local redis = require "resty.redis" --加载redis库

local LIST_LEN = 100  --设定长度
local LIST_NAME = "BACK_SERVER_STATUS"

Redis_Class = class('Redis_Class')


function Redis_Class:initialize(code, uri, backurl)
    self.host = "192.168.28.4"
    self.port = 6379
    self.max_idle_timeout = 1000*60
    self.pool_size = 50

    self.red = redis:new() --实例化redis类
    

    self.code = code or ngx.HTTP_INTERNAL_SERVER_ERROR
    self.uri = uri or "/"
    self.backurl = backurl or "localhost"
end

function Redis_Class:connect() --连接redis服务器
		
	local red = self.red
	red:set_timeout(1000) -- 1 sec
             

	local ok, err = red:connect(self.host, self.port) --连接 redis 服务器

	if not ok then  --如果连接出错
	    ngx.log(ngx.ERR, "failed to connect redis server: " .. err)
	    return false, err
        end
	
	local times, err = red:get_reused_times()	

	if(not times or times == 0) then  --如果未从连接池获取数据

	    ngx.log(ngx.NOTICE, "redis failed to use connection pool") 

	end

	return true, nil
end

function Redis_Class:close_conn()
	local red = self.red

	local ok, err = red:set_keepalive(self.max_idle_timeout, self.pool_size)

	if not ok then  --如果设置连接池出错
	    ngx.log(ngx.ERR, "redis failed to set connect pool: " .. err) 
        end

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


	local length, err = red:rpush(LIST_NAME .. self.uri, self:parse())
	
	if(not length) then --如果插入失败
	    self:close_conn()
	    ngx.log(ngx.ERR, "failed to lpush list: " .. err) 
	    return false, err
	end

	if(length > LIST_LEN) then  --如果list超长

	    local res,err = red:ltrim(LIST_NAME .. self.uri, 9,-9) --出列10个

	    if(not length) then --如果出列失败
		self:close_conn()
		ngx.log(ngx.ERR, "failed to ltrim list: " .. err) 
	        return false, err
	    end

	end
	
	self:close_conn()

	return true, nil
end



function Redis_Class:get_record() --获取访问日志

	local red = self.red
	local ok, err =self:connect()
	
	if not ok then  --如果连接出错
	    return ok, err
        end
	
	local keys, err = red:keys(LIST_NAME.."*") --获取所有类似key
	
	red:init_pipeline() --初始化流水线，将命令一次性提交

	for i,v in ipairs(keys) do  --录入流水线命令
	
		red:lrange(v, 0, LIST_LEN)

	end

	local list,err = red:commit_pipeline() --提交redis命令，等待流水线返回
	
	if(not list) then --如果发生错误
	    ngx.log(ngx.ERR, "lrange list ".. LIST_NAME .." error") 
	    self:close_conn()
	    return false, "lrange list error"
	end
	
	self.cahce={}
	
	for i,v in ipairs(list) do  --循环输出结果放入数组，等待最后concat

            for j,u in ipairs(v) do
		
		table.insert(self.cahce, u)

	    end

	end

	--ngx.log(ngx.ERR, "#########################", table.concat(self.cahce,",")) 
	
	self.jsonstr = "[" .. table.concat(self.cahce,",") .. "]"
	
	self:close_conn()

	return true, nil
end


