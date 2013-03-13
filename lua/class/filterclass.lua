module("filterclass", package.seeall)


local Req_Class = require "reqclass"["Req_Class"] --req类

local API_SECRET = "ApiSecret"
local API_KEY = "apikey"
local SIGN ="sign"
local SERVICE_PATH = "servicepath"
local VERIFY_TYPE = "verifytype"
local API_USER = "apiuser"
local CLIENT_ID = "client_id"
local cache = ngx.shared.cache

Filter = class('Filter', Req_Class) -- 继承Req_Class类


function Filter:initialize()
    Req_Class.initialize(self) -- 执行req的构造函数initialize

    self._args_table = {} --存放参数的table

    local ok, err = pcall(function() --反解码json
        local jsonstr = cache:get(self:cut_path()) or '{"_err":true}' --根据请求uri获取share.dict.cache数据
		

	local table_json = cjson.decode(jsonstr) --对json解码

	--如果没匹配到
        if(table_json["_err"]) then
              self.service_table = nil --则将 service_table 设置为nil
        else
	      self.service_table = table_json
	end

    end)

    --如果json解析出错
    if not ok then
        ngx.log(ngx.ERR, "json string decode error") --出错记录错误日志
        self.err = true
    end

end


--check_all 根据数据判断是否合法
function Filter:check_all()
    
    --如果json decode出错的话，则返回内部错误
    if self.err then
	return ngx.HTTP_INTERNAL_SERVER_ERROR, "-10009"
    end

    --判断req的数据是否合法
    if(self.req_data_error) then
	return ngx.HTTP_BAD_REQUEST, "-10013"
    end

    --判断请求uri是否找到
    if not(self:check_uri()) then
        return ngx.HTTP_NOT_FOUND, "-10011"
    end

    
    if(self.service_table[VERIFY_TYPE] == 1) then   -- 判断是否需要签名

        
	if(not(self:check_method())) then   --如果请求方法不对则执行
	    return ngx.HTTP_BAD_REQUEST, "-10010"
	end

	if(not(self:check_has_sign())) then   --判断是否含有sign参数
	    return ngx.HTTP_BAD_REQUEST, "-10003"
	end

	if(not(self:check_has_api_key())) then   --判断是否含有client_id
	    return ngx.HTTP_BAD_REQUEST, "-10005"
	end

	if(not(self:check_api_key())) then   --判断client_id是否有效
	    return ngx.HTTP_UNAUTHORIZED, "-10006"
	end

	if(not(self:check_sign())) then   --判断sign是否合法
	    return ngx.HTTP_UNAUTHORIZED, "-10004"
	end

        return ngx.HTTP_OK, "null"

    else

       return ngx.HTTP_OK, "null"

    end

end


--判断请求方法是否含有此uri
function Filter:check_uri()
    return self.service_table
end



--判断请求方法是否合法
function Filter:check_method()
    return self.service_table.httpmethod == self._method
end



--判断是否含有 sign
function Filter:check_has_sign()   
    if(self.request_args[SIGN]) then
	return true
    end
        return false 
end


--判断是否含有 apikey
function Filter:check_has_api_key()   
    if(self.request_args[CLIENT_ID]) then
	return true
    end
        return false 
end


--判断是否具有api key合法性
function Filter:check_api_key()   
    local api_key = self.request_args[CLIENT_ID] --获取请求的client_id参数

    for i,v in ipairs(self.service_table[API_USER]) do --遍历api_user list查看是否有匹配
	if(v[API_KEY] == api_key) then
	    self._api_secret = v[API_SECRET] --获得api secret密钥
	    return true
	end
    end
    
    return false
end



--判断签名sign是否合法
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




function Filter:cut_path() --将uri统一切成末尾不带 / 和小写
     local uri = string.lower(self.req_uri or "/")
     local l = string.len(uri)
     local pos = string.find(uri, '/', -1)

     if(l == pos) then
	 uri = uri:sub(1,l-1)
     end

     self.req_uri = uri
     return uri
end