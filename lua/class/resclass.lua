--Res_Class类，主要封装了对客户端使用api响应的一些属性和方法


--常量定义

local DEFAULT_RES_TYPE = 'json'
local ENCODE_TABLE = {}
ENCODE_TABLE.json = {
   encode = cjson.encode,
   header = "application/json" 
}

ENCODE_TABLE.str = {
   encode = function(str) return str end,
   header = "text/html" 
}



local RES_MSG = {}
RES_MSG[ngx.HTTP_OK] = ngx.HTTP_OK .. " ok"
RES_MSG[ngx.HTTP_CREATED] = ngx.HTTP_CREATED .. " created"
RES_MSG[ngx.HTTP_SPECIAL_RESPONSE] = ngx.HTTP_SPECIAL_RESPONSE .. " special response"
RES_MSG[ngx.HTTP_MOVED_PERMANENTLY] = ngx.HTTP_MOVED_PERMANENTLY .. " moved permanently"
RES_MSG[ngx.HTTP_MOVED_TEMPORARILY] = ngx.HTTP_MOVED_TEMPORARILY .. " moved temporarily"
RES_MSG[ngx.HTTP_SEE_OTHER] = ngx.HTTP_MOVED_TEMPORARILY .. " see other"
RES_MSG[ngx.HTTP_NOT_MODIFIED] = ngx.HTTP_NOT_MODIFIED .. " not modified"
RES_MSG[ngx.HTTP_BAD_REQUEST] = ngx.HTTP_BAD_REQUEST .. " bad request"
RES_MSG[ngx.HTTP_UNAUTHORIZED] = ngx.HTTP_UNAUTHORIZED .. " unauthorized"
RES_MSG[ngx.HTTP_FORBIDDEN] = ngx.HTTP_FORBIDDEN .. " forbidden"
RES_MSG[ngx.HTTP_NOT_FOUND] = ngx.HTTP_NOT_FOUND .. " not found"
RES_MSG[ngx.HTTP_NOT_ALLOWED] = ngx.HTTP_NOT_ALLOWED .. " not allowed"
RES_MSG[ngx.HTTP_GONE] = ngx.HTTP_GONE .. " gone"
RES_MSG[ngx.HTTP_INTERNAL_SERVER_ERROR] = ngx.HTTP_INTERNAL_SERVER_ERROR .. " http internal server error"
RES_MSG[ngx.HTTP_METHOD_NOT_IMPLEMENTED] = ngx.HTTP_METHOD_NOT_IMPLEMENTED .. " http method not implemented"
RES_MSG[ngx.HTTP_SERVICE_UNAVAILABLE] = ngx.HTTP_SERVICE_UNAVAILABLE .. " service unavailable"
RES_MSG[ngx.HTTP_GATEWAY_TIMEOUT] = ngx.HTTP_GATEWAY_TIMEOUT .. " gateway timeout"






ERROR_MSG = {}
ERROR_MSG["-10000"] = "auth faild"
ERROR_MSG["-10001"] = "unsupport protocol"
ERROR_MSG["-10002"] = "invalid client_id"
ERROR_MSG["-10003"] = "sign not given"
ERROR_MSG["-10004"] = "invalid sign"
ERROR_MSG["-10005"] = "client_id not given"
ERROR_MSG["-10006"] = "client_id not Authorize"
ERROR_MSG["-10007"] = "unsupport mediatype"
ERROR_MSG["-10008"] = "method not implemented"
ERROR_MSG["-10009"] = "unknow system error"
ERROR_MSG["-10010"] = "method not allowed"
ERROR_MSG["-10011"] = "service not found"
ERROR_MSG["-10012"] = "service not ready"
ERROR_MSG["-10013"] = "param error"

ERROR_MSG["-10015"] = "forbidden"
ERROR_MSG["-10016"] = "unauthorized"



--利用midclass创建Res_Class类
Res_Class = class('Res_Class')


--构造函数
function Res_Class:initialize(args)
    local args = args or {}
    self._error_code = args.error_code or "null"   -- 默认状态码为200 ok
    self._res_type = args.res_type or DEFAULT_RES_TYPE 
    self.pre_res_table = {}
end


--设置res的响应状态码
function Res_Class:set_status_code(res_code)
    self._status_code =  res_code
    ngx.status = res_code
    return self
end

--更改返回类型默认为json
function Res_Class:change_res_type(res_type)
    self._res_type = res_type or DEFAULT_RES_TYPE
    return self
end


--响应数据send方法
function Res_Class:send(ops)
    local res_table = {}
    local ops = ops or {}
    self._error_code = ops.error_code or self._error_code
    local status = ops.status or ngx.HTTP_OK

    if(status == ngx.HTTP_OK) then
	res_table.result = true
	res_table.error = "null"
        res_table.error_code = -1
	res_table.request = "null"
    else
	res_table.result = false
	res_table.error_code = tonumber(self._error_code)
	res_table.error = ERROR_MSG[self._error_code]
	res_table.request = ngx.var.uri
    end

    
    
    self:set_status_code(ops.status or ngx.HTTP_OK)
    self:set_header("Content-type",ENCODE_TABLE[self._res_type].header)

    ngx.say(ENCODE_TABLE[self._res_type].encode(res_table))
    self.pre_res_table = res_table
    return self
end

--快速响应200ok
function Res_Class:send_ok()
   self:send({status=ngx.HTTP_OK, error_code = "null"})
   return self
end




--快速响应401 unauthorized
function Res_Class:send_unauthorized()
   self:send({status=ngx.HTTP_UNAUTHORIZED, error_code = "-10016"})
   return self
end



--快速响应403 forbidden
function Res_Class:send_forbidden()
   self:send({status=ngx.HTTP_FORBIDDEN, error_code = "-10015"})
   return self
end


--快速响应404 not found
function Res_Class:send_not_found()

   self:send({status=ngx.HTTP_NOT_FOUND,error_code = "-10011"})
   return self
end


--快速响应500 server error
function Res_Class:send_server_error()
   self:send({status=ngx.HTTP_INTERNAL_SERVER_ERROR,error_code = "-10009"})
   return self
end


--快速响应501 not_implemented
function Res_Class:send_not_implemented()
 
   self:send({status=ngx.HTTP_METHOD_NOT_IMPLEMENTED, error_code = "-10008"})
   return self
end

--快速响应503 unavailable
function Res_Class:send_unavailable()
   self:send({status=ngx.HTTP_SERVICE_UNAVAILABLE, error_code = "-10012"})
   return self
end

--设置响应头set_header
function Res_Class:set_header(h,v)
   if(h and v) then
	ngx.header[h] = v
   end
   return self
end