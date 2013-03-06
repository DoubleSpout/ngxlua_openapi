--根据mysql数据库查询是否需要sign然后进行rewrite

require('filterclass')
require('resclass')
require('mysqlclass')
require('transclass')

local res = Res_Class:new()

local code, db, err = Mysql_CLass:connect()
if(code ~= ngx.HTTP_OK) then
   res:send({status=code,data=err})
   return 
end

local code, service_table, error_code = Mysql_CLass:query_api_service(db, ngx.var.uri)

if(code ~= ngx.HTTP_OK) then
   return res:send({status=code, error_code = error_code})   
end

local req = Filter:new(service_table)

local code, error_code = req:check_all()


if(code ~= ngx.HTTP_OK) then
   return res:send({status=code, error_code = error_code})   
end


local http = Http_Class:new(nil,nil,req.header,req:get_method(),req:get_body())

local ok, code, headers, status, body = http:send_request()



if(code ~= ngx.HTTP_OK) then
    ngx.log(ngx.ERR, "request " .. http.url .." error: " .. code..' body: '.. http.data or "") --出错记录错误日志
    res:send_unavailable()
else
    ngx.say(http.data)
end















