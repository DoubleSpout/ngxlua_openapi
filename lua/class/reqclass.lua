



--对用户请求过来的参数，uri等各种处理的类

--利用midclass创建Req_Class类

module("reqclass", package.seeall)


Req_Class = class('Req_Class')

--构造函数
function Req_Class:initialize()

    self._method = ngx.req.get_method()
    self._uri_args = ngx.req.get_uri_args()
    self.request_args = ngx.req.get_uri_args() or {} --赋值uri参数键值表
    self.header = ngx.req.get_headers()
    self.req_uri = ngx.var.uri
    self.header["X-Real-IP"] = ngx.var.remote_addr --获取用户真实ip，不可靠
    
    if(self._method == "POST" and self.header["content-type"]  --如果是post请求，且头部不正确，则记录错误
    ~= "application/json" and  self.header["content-type"] 
    ~= "application/x-www-form-urlencoded") then
	 self.req_data_error = true
	 return
    end

    
    if(self:_check_read_body()) then  --如果检查body需要read_body方法
        ngx.req.read_body()
	self._body_data = ngx.req.get_body_data() --将原始body存入 _body_data
        
	if(self.header["content-type"] == "application/json") then --如果提交过来的头部是json格式
	     local ok, res_json = pcall(function() return --异常捕获，当用户提交不是json格式
		cjson.decode(self._body_data)
	     end)
             
	     if(ok) then
	        self._post_args = res_json  --将解析出来的json字符串对象保存为 _post_args
	     else
	        self.req_data_error = true
		return
	     end
	else 
	     self._post_args = ngx.req.get_post_args() --如果不是json，则直接保存 _post_args
	end
	
	for k,v in pairs(self._post_args) do  --将url和_post_args的参数结合起来，优先url参数
	     if(not self.request_args[k]) then
                  self.request_args[k] = v
	     end
	end

    else

	self._post_args = {} --如果不需要read_body，则把 _post_args 置空
    end
    
end


--检查是否执行readbody
function Req_Class:_check_read_body()
    if(self._method == "POST" or self._method == "PUT") then
	return true
    end

    return false
    
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



