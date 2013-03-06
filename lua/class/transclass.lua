--转发http请求的类


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
function Http_Class:initialize(host,url,header,method,body)
    if(host and url) then
           self.url = "http://" .. host .. url 
    else
           self.url = DEF_URL
    end

    self.method = method or DEF_METHOD
    self.header = {}
    local body = body

    if(self.method == "POST" or self.method == "PUT") then
        if(self.header["Content-Type"] ~= DEF_FORM_HEAD and self.header["Content-Type"] ~= DEF_JSON_HEAD) then
		self.header["Content-Type"] = DEF_FORM_HEAD
	end
	self.header["Content-Length"] = nil
	--self.header["Transfer-Encoding"] = "chunked"
	body = body or {}
    end
       
    local x_forwarded_for
    if(not ngx.var.proxy_add_x_forwarded_for) then
        x_forwarded_for = ngx.var.remote_addr
    else
	x_forwarded_for = ngx.var.proxy_add_x_forwarded_for .. "," .. ngx.var.remote_addr
    end

    self.header["X-Real-IP"] = ngx.var.remote_addr
    self.header["X-Forwarded-For"] =x_forwarded_for
    self.header["Host"] = host or DEF_HOST

    self.body = body

    self.http_client = http:new()
end

function Http_Class:send_request()
	
	self.data_array = {}

	local ok, code, headers, status, body = self.http_client:proxy_pass {
		url = self.url,
		headers = self.header,
		method = self.method,
		body = self.body,
		body_callback = function(data, ...)		   
		   table.insert(self.data_array, data)
		end
	}
	
	if(ngx.header["Transfer-Encoding"]) then
		ngx.header["Transfer-Encoding"] = nil
	end
	
	if(ngx.header["Connection"]) then
		ngx.header["Connection"] = nil
	end

	self.data = table.concat(self.data_array, "")

	return ok, code, headers, status, body
end










