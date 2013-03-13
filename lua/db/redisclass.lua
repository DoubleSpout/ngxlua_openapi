local redis = require "resty.redis" --加载redis库

local LIST_LEN = 20  --设定长度
local LIST_NAME = "BACK_SERVER_STATUS"

Redis_Class = class('Redis_Class')


function Redis_Class:initialize(code, uri, backurl)
    self.host = "192.168.28.4"
    self.port = 6379
    self.max_idle_timeout = 1000*60
    self.pool_size = 100

    self.red = redis:new() --实例化redis类
    

    self.code = code or ngx.HTTP_INTERNAL_SERVER_ERROR
    self.uri = uri or "/"
    self.backurl = backurl or "localhost"
end

function Redis_Class:connect() --连接redis服务器
		
	local red = self.red
	red:set_timeout(1000) -- 1 sec
        
	--[[
	local ok, err = red:set_keepalive(self.max_idle_timeout, self.pool_size)
	
	if not ok then  --如果设置连接池出错
	    ngx.log(ngx.ERR, "failed to set connect pool: " .. err) 
	    return false, err
        end
	--]]        

	local ok, err = red:connect(self.host, self.port) --连接 redis 服务器

	if not ok then  --如果连接出错
	    ngx.log(ngx.ERR, "failed to connect redis server: " .. err)
	    return false, err
        end
	
	return true, nil
end


function Redis_Class:parse() --记录访问日志,创建其格式

	local ts = os.time()
	return cjson.encode({timestamp=ts, uri=self.uri, backurl=self.backurl, code=self.code})   

end


function Redis_Class:record() --记录访问日志

	local red = self.red
	local ok, err =self:connect()


	if not ok then  --如果连接出错
	    return ok, err
        end
	
	local length, err = red:rpush(LIST_NAME, self:parse())
	
	if(not length) then --如果插入失败
	    ngx.log(ngx.ERR, "failed to lpush list: " .. err) 
	    return false, err
	end

	if(length > LIST_LEN) then  --如果list超长

	    local res,err = red:ltrim(LIST_NAME, 9,-9) --出列10个

	    if(not length) then --如果出列失败
		ngx.log(ngx.ERR, "failed to ltrim list: " .. err) 
	        return false, err
	    end

	end

	return true, nil
end



function Redis_Class:get_record() --获取访问日志

	local red = self.red
	local ok, err =self:connect()
	
	if not ok then  --如果连接出错
	    return ok, err
        end
	
	local list,err = red:lrange(LIST_NAME, 0, LIST_LEN)
	self.jsonstr = "[" .. table.concat(list,",") .. "]"
	
	if(not list) then
	    ngx.log(ngx.ERR, "lrange list ".. LIST_NAME .." error") 
	    return false, "lrange list error"
	end
	
	return true, nil
end






















local red = redis:new()


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

end


function Mysql_CLass:connect()
		
        local db, err = mysql:new()
        if not db then
	    ngx.log(ngx.ERR, "mysql library error " .. err) --出错记录错误日志，无法加载mysql库
            return ngx.HTTP_INTERNAL_SERVER_ERROR, nil, ERR_MYSQL_LIB --返回错误code
        end

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

	return ngx.HTTP_OK, db, nil --连接成功返回ok状态码

end



function Mysql_CLass:query_all_api_service(db)

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

   local code, err = self:query_all_api_service(db)

   if(code ~= ngx.HTTP_OK) then
       db_connect_code = code
       return code, err
   end

   --db:close()

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


