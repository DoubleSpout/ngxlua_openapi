--根据mysql数据库查询是否需要sign然后进行rewrite
require "mysqlclass" --数据库db类


local mysql = Mysql_CLass:new() --实例化mysql类
local code, err = mysql:rebuild()  -- 初始化获取数据，如果有缓存则读缓存


if(code ~= ngx.HTTP_OK) then --如果数据初始化失败，则直接返回db错误
   return ngx.say("rebuild cache failed")
end


ngx.say("rebuild cache success")

