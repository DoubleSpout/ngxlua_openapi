
local Res_Class = require "resclass"["Res_Class"] --res类
local Redis_Class =  require "redisclass"["Redis_Class"] --想后端发送请求类

local res = Res_Class:new() --实例化res类

if(ngx.req.get_method() ~= "GET") then --如果不是get请求，则返回错误
    res:send_not_implemented()
end


local req_param_uri = string.lower(ngx.req.get_uri_args()["uri"] or "")


--坑爹，这样访问会变成true：http://test.api6998.com/status?uri
if(not(req_param_uri) or req_param_uri == true) then 
     req_param_uri = nil
end


local redis = Redis_Class:new(nil,req_param_uri) --实例化redis类
local list, err = redis:get_record() --记录访问日志

if(not list) then

     res:send_server_error()

end

ngx.header["Content-type"] = "application/json"
ngx.say(redis.jsonstr)

