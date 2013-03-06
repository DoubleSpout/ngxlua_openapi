--对用户请求过来的参数，uri等各种处理的类

--利用midclass创建Req_Class类
Req_Class = class('Req_Class')

--构造函数
function Req_Class:initialize()

    self._method = ngx.req.get_method()
    self._uri_args = ngx.req.get_uri_args()
    self.request_args = ngx.req.get_uri_args() or nil
    self.header = ngx.req.get_headers()
    self.req_uri = ngx.var.uri
    self.header["X-Real-IP"] = ngx.var.remote_addr
    
    if(self._method == "POST" and self.header["content-type"] ~= "application/json" and  self.header["content-type"] ~= "application/x-www-form-urlencoded") then
	 self.req_data_error = true
	 return
    end

    
    if(self:_check_read_body()) then
        ngx.req.read_body()
	self._body_data = ngx.req.get_body_data()
        
	if(self.header["content-type"] == "application/json") then
	     local status, res_json = pcall(function() return --异常捕获，当用户提交不是json格式
		cjson.decode(self._body_data) 
	     end)
             
	     if(status) then
	        self._post_args = res_json
		
	     else
	        self.req_data_error = true
		return
	     end
	else 
	     self._post_args = ngx.req.get_post_args()
	end
	
	for k,v in pairs(self._post_args) do
	     if(not self.request_args[k]) then
                  self.request_args[k] = v
	     end
	end

    else

	self._post_args = {}
    end
    
end


--检查是否执行readbody
function Req_Class:_check_read_body()
    if(self._method == "POST" or self._method == "PUT") then
	return true
    else
	return false
    end
end


--返回req的请求方法
function Req_Class:get_method()

    return self._method
end


--返回req的uri请求参数和值
function Req_Class:get_uri_args()

    return self._uri_args
end


--返回req的post请求参数和值
function Req_Class:get_post_args()
   return self._post_args
end


--返回req的body原始数据
function Req_Class:get_body()
   return self._body_data
end



