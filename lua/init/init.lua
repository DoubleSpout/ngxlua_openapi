--ngx_lua启动执行这里，将一些常用的数据缓存在此，避免每次request都去请求数据库，减少i/o

	
require("cjson")	
require("ngx")
require("middleclass")




ngx.log(ngx.NOTICE, 'lua init finished')


