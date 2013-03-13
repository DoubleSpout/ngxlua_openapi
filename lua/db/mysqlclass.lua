local mysql = require "resty.mysql"


local ERR_MYSQL_LIB = "could not open mysql library"
local ERR_MYSQL_DB = "could not open mysql database"
local ERR_MYSQL_ERROR = "mysql occur error"

local cache = ngx.shared.cache





Mysql_CLass = class('Mysql_CLass')

function Mysql_CLass:initialize()
    self.host = "192.168.28.4"
    self.port = 3306
    self.database = "openapi"
    self.user = "root"
    self.password = "123456"
    self.max_packet_size =  1024 * 1024

    self.max_idle_timeout = 1000*60
    self.pool_size = 10

end


function Mysql_CLass:connect()
		
        local db, err = mysql:new()

        if not db then
	    ngx.log(ngx.ERR, "mysql library error " .. err) --出错记录错误日志，无法加载mysql库
            return ngx.HTTP_INTERNAL_SERVER_ERROR, nil, ERR_MYSQL_LIB --返回错误code
        end
	
	self.db = db

        db:set_timeout(3000) -- 设定超时间3 sec

	local ok, err, errno, sqlstate = db:connect{ --建立数据库连接
                   host = self.host,
                   port = self.port,
                   database = self.database,
                   user = self.user,
                   password = self.password,
                   max_packet_size = self.max_packet_size 
		}

	if not ok then --如果连接失败
	      ngx.log(ngx.ERR, "mysql not connect: " .. err .. ": " .. errno) --出错记录错误日志
	      return ngx.HTTP_INTERNAL_SERVER_ERROR, nil, ERR_MYSQL_DB --返回错误code
        end
	
	local times, err = db:get_reused_times()	

	if(not times or times == 0) then  --如果未从连接池获取数据

	    ngx.log(ngx.NOTICE, "mysql failed to use connection pool") 

	end

	return ngx.HTTP_OK, db, nil --连接成功返回ok状态码

end


function Mysql_CLass:close_conn() --关闭mysql连接封装
	 
	 local db = self.db
	 
	 local ok, err = db:set_keepalive(self.max_idle_timeout, self.pool_size) --将本链接放入连接池

	 if not ok then  --如果设置连接池出错
	    ngx.log(ngx.ERR, "mysql failed to set connect pool: " .. err) 
         end
	
end



function Mysql_CLass:query_all_api_service()
	
	 local db = self.db

	 local api_service_table = {} --定义局部变量存放所有的apiservice对象
	 
	 local res, err, errno, sqlstate =  --查询 ApiServices 表
              db:query("select id,servicename,servicepath,httpmethod,verifytype,routerpath,serviceroleid from ApiServices where enable = 1 " )
        
	 if not res then
	      --如果ApiServices表查询出错
              ngx.log(ngx.ERR, "get api services error: " .. err .. ": " .. errno .. ": ".. sqlstate .. ".") --出错记录错误日志
              return ngx.HTTP_INTERNAL_SERVER_ERROR, ERR_MYSQL_ERROR
         end
	 

	 api_service_table = res 
         
	 --遍历 api_service_table 对象，将有 serviceroleid 的项做第二次查询，查找apiuser列表
	 for i,v in ipairs(api_service_table) do
	   
	      if(v.serviceroleid == ngx.null) then
	           v.serviceroleid = nil
	      else
		   local role_id = v.serviceroleid

		   local res2, err, errno, sqlstate =  --联表查询
                          db:query("SELECT name,apikey,ApiSecret from ApiUserRoleTag as a JOIN ApiUser as b ON a.ApiUserId = b.id where a.ServiceRoleId = " .. role_id )
		   
		   if not res2 then
		       --如果Api user表查询出错
                       ngx.log(ngx.ERR, "get role list error: " .. err .. ": " .. errno .. ": ".. sqlstate .. ".") --出错记录错误日志
                       return ngx.HTTP_INTERNAL_SERVER_ERROR, ERR_MYSQL_ERROR
	           end
	           
		   v.apiuser = res2 --将查询出的list存入 api_service_table 值的 apiuser 

	      end


	      --将url作为key名，json字符串v存入share的dict.cache
              local ok,err = pcall(function() 
		    cache:set(v["servicepath"], cjson.encode(v))
	      end)

	      --如果table转json字符串出错
              if not ok then
		    ngx.log(ngx.ERR, "json encode error: "..err)
		    return ngx.HTTP_INTERNAL_SERVER_ERROR, err
              end
	 end
         
	 cache:set("_is_cache", "true")

	 return ngx.HTTP_OK, nil

end



function Mysql_CLass:rebuild() --重建缓存方法
   
   cache:flush_all() --清空缓存

   local code, db, err = self:connect() --建立数据库连接
   
   if(code ~= ngx.HTTP_OK) then --如果数据库连接建立失败
       db_connect_code = code
       return code, err
   end

   local code, err = self:query_all_api_service()

   if(code ~= ngx.HTTP_OK) then -- 如果更新缓存失败

       db_connect_code = code
       self:close_conn()  --关闭mysql连接
       return code, err

   end

   self:close_conn()  --关闭mysql连接

   return code, nil

end



function Mysql_CLass:init() --初始化数据

    if(cache:get("_is_cache") == "false" or not(cache:get("_is_cache"))) then  --如果没有缓存,则去重建
       ngx.log(ngx.NOTICE, "data from db")
       return self:rebuild() --去重建缓存
    end

    ngx.log(ngx.NOTICE, "data from cache")   
    return ngx.HTTP_OK --从缓存读取
end


