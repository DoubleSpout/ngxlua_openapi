
--压力测试接口，直接返回ok，不去后端再走一圈了


local Mysql_Class = require "mysqlclass"["Mysql_CLass"] --数据库db类
local Filter = require "filterclass"["Filter"] --过滤类，继承req类
local Res_Class = require "resclass"["Res_Class"] --res类
local Http_Class = require "transclass"["Http_Class"] --想后端发送请求类
local Redis_Class = require "redisclass"["Redis_Class"] --想后端发送请求类



ngx.req.set_uri("/api/messages/sendmail", false) --重写请求uri路径，false表示不跳转


local res = Res_Class:new() --实例化res类
local mysql = Mysql_Class:new() --实例化mysql类


local code, err = mysql:init()  -- 初始化获取数据，如果有缓存则读缓存

if(code ~= ngx.HTTP_OK) then --如果数据初始化失败，则直接返回db错误
   return res:send({status=500, error_code = "-10017"}) 
end

--实例化filter类
local req = Filter:new()

--开始过滤数据
local code, error_code = req:check_all()


--如果过滤失败，则返回响应的错误信息
if(code ~= ngx.HTTP_OK) then
   return res:send({status=code, error_code = error_code})   
end


--redis记录访问日志
local redis = Redis_Class:new(nil, req.req_uri, nil) --实例化redis类
redis:record() --记录访问日志


ngx.say("test ok")


