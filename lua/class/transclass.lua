--转发http请求的类

module("transclass", package.seeall)

local http = require('resty.http')

local DEF_HOST = "192.168.28.4"
local DEF_URL = "http://192.168.28.4:3000"
local DEF_HEADER = {}
local DEF_METHOD = "GET"
local DEF_BODY = {}
local DEF_FORM_HEAD = "application/x-www-form-urlencoded"
local DEF_JSON_HEAD = "application/json"


Http_Class = class('Http_Class')

--构造函数
function Http_Class:initialize(host, url, header, method, body)
    if(host and url) then    -- 如果没有传递了host 和 url 则拼接http url
           self.url = "http://" .. host .. url 
    else
           self.url = DEF_URL
    end

    self.method = method or DEF_METHOD
    self.header = {}
    local body = body

    if(self.method == "POST" or self.method == "PUT") then --如果是post或者put提交
        if(self.header["Content-Type"] ~= DEF_FORM_HEAD and self.header["Content-Type"] ~= DEF_JSON_HEAD) then --修正content-type
		self.header["Content-Type"] = DEF_FORM_HEAD
	end
	self.header["Content-Length"] = nil
	--self.header["Transfer-Encoding"] = "chunked"
	body = body or {}
    end
       
    local x_forwarded_for
    if(not ngx.var.proxy_add_x_forwarded_for) then 
        x_forwarded_for = ngx.var.remote_addr --如果用户么有使用代理
    else
	x_forwarded_for = ngx.var.proxy_add_x_forwarded_for .. "," .. ngx.var.remote_addr --如果用于使用代理，则再上 x_forwarded_for
    end

    self.header["X-Real-IP"] = ngx.var.remote_addr
    self.header["X-Forwarded-For"] =x_forwarded_for
    self.header["Host"] = host or DEF_HOST

    self.body = body

    self.http_client = http:new()
end

function Http_Class:send_request()
	
	local data_array = {}

	local ok, code, headers, status, body = self.http_client:proxy_pass {
		url = self.url,
		headers = self.header,
		method = self.method,
		body = self.body,
		body_callback = function(data, ...)  --注意，这里会执行多次，会以chunk的形式返回   
		   table.insert(data_array, data) --将chunk放入数组
		end
	}

	if(not ok) then -- 如果请求发送失败
            ngx.log(ngx.ERR, "http request error, url is " .. self.url) --出错记录错误日志
	    return false, ngx.HTTP_INTERNAL_SERVER_ERROR, self.url --如果出错，返回OK 为false和请求url地址
	end

	if(ngx.header["Transfer-Encoding"]) then  --删除多余的header
		ngx.header["Transfer-Encoding"] = nil
	end
	
	if(ngx.header["Connection"]) then --删除多余的header
		ngx.header["Connection"] = nil
	end
	
	ngx.status = status

	self.data = table.concat(data_array, "") -- 将数组中的数据拼起来      
	
	return true, status, self.url  --返回true和状态码
end










