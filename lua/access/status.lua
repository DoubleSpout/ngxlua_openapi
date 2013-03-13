
require "resclass" --res类
require "redisclass" --想后端发送请求类

local res = Res_Class:new() --实例化res类

if(ngx.req.get_method() ~= "GET") then --如果不是get请求，则返回错误
    res:send_not_implemented()
end


local redis = Redis_Class:new() --实例化redis类
local list, err = redis:get_record() --记录访问日志

if(not list) then
     res:send_server_error()
end

ngx.header["Content-type"] = "application/json"
ngx.say(redis.jsonstr)

