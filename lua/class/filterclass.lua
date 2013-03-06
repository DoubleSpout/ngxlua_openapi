require("reqclass")

local API_SECRET = "ApiSecret"
local API_KEY = "apikey"
local SIGN ="sign"
local SERVICE_PATH = "servicepath"
local VERIFY_TYPE = "verifytype"
local API_USER = "apiuser"
local CLIENT_ID = "client_id"

Filter = class('Filter', Req_Class) -- 继承Req_Class类
function Filter:initialize(args)
    Req_Class.initialize(self) -- 执行构造函数的initialize
    self.service_table = args    
    self._args_table = {}
end


--check_all 根据数据判断是否合法
function Filter:check_all()
	
    if(self.req_data_error) then
	return ngx.HTTP_BAD_REQUEST, "-10013"
    end

    if(not(self.service_table[SERVICE_PATH])) then   --如果没有匹配到路由
        return ngx.HTTP_NOT_FOUND, "-10011"
    end
    
    if(self.service_table[VERIFY_TYPE] == 1) then   -- 判断是否需要签名
	
	if(not(self:check_method())) then   --如果请求方法不对则执行
	    return ngx.HTTP_BAD_REQUEST, "-10010"
	end

	if(not(self:check_has_sign())) then   --如果请求方法不对则执行
	    return ngx.HTTP_BAD_REQUEST, "-10003"
	end

	if(not(self:check_has_api_key())) then   --如果请求方法不对则执行
	    return ngx.HTTP_BAD_REQUEST, "-10005"
	end

	if(not(self:check_api_key())) then   --如果请求方法不对则执行
	    return ngx.HTTP_UNAUTHORIZED, "-10006"
	end

	if(not(self:check_sign())) then   --如果请求方法不对则执行
	    return ngx.HTTP_UNAUTHORIZED, "-10004"
	end

        return ngx.HTTP_OK, "null"

    else

       return ngx.HTTP_OK, "null"

    end

end


--判断请求方法是否合法
function Filter:check_method()
    return self.service_table.httpmethod == self._method
end



--判断是否含有 sign
function Filter:check_has_sign()   
    if(self.request_args[SIGN]) then
	return true
    else
        return false 
    end
end


--判断是否含有 apikey
function Filter:check_has_api_key()   
    if(self.request_args[CLIENT_ID]) then
	return true
    else
        return false 
    end
end


--判断是否具有api key合法性
function Filter:check_api_key()   
    local api_key = self.request_args[CLIENT_ID]

    for i,v in ipairs(self.service_table[API_USER]) do
	if(v[API_KEY] == api_key) then
	    self._api_secret = v[API_SECRET]
	    return true
	end
    end
    
    return false
end



--判断前面是否合法
function Filter:check_sign()   
    local i=0;
    self._args_table = {}
    for k,v in pairs(self.request_args) do
        if(k ~= SIGN) then
	   table.insert(self._args_table,k)
        end
    end

    table.sort(self._args_table)
    
    local kv_table = {}
    for i,v in ipairs(self._args_table) do        
	table.insert(kv_table, v .. '=' .. tostring(self.request_args[v]))
    end
    local sign_local = table.concat(kv_table, '&')

    sign_local = ngx.md5(sign_local  .. self._api_secret)
    
    if(sign_local == self.request_args[SIGN]) then
       return true
    end
    
    return false;

end




