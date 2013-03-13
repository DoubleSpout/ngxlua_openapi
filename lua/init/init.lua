--ngx_lua启动执行这里，将一些常用的数据缓存在此，避免每次request都去请求数据库，减少i/o
	
require "cjson"	--cjson库
require "ngx" --ngx库
require "middleclass" --lua 对象增强库


local cache = ngx.shared.cache

--增加全局db连接
local suc = cache:add("_is_cache", "false")

--如果出错则记录初始化失败
if not suc then
    ngx.log(ngx.ERR, 'lua init failed')
end


ngx.log(ngx.NOTICE, 'lua init finished')


