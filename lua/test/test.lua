--测试用例


DEFAULT_HOST = "127.0.0.1"
DEFAULT_URL = "/api/Messages/SendSms/"
DEFAULT_FORM_STR = "client_id=test1&sign=8659759eb5f579f322defb06586abfb0"
DEFAULT_JSON_STR = '{"client_id":"test1","sign":"8659759eb5f579f322defb06586abfb0"}'

function trim(s)
    return s:gsub("^%s*(.-)%s*$", "%1")
end

do   --发送不存在的uri请求

local res = ngx.location.capture("/api/Messages/SendSms123/",{})

local code = res.status
local data = trim(res.body)

ngx.say("code == 404 : "..tostring(assert(code==404)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms123\\/","error_code":-10011,"error":"service not found"}'

ngx.log(ngx.ERR, data)

ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送不存在的uri请求，测试完毕')

end




do   --发送不存在的sign请求

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="aaa=111"})


local code = res.status
local data = trim(res.body)


--ngx.log(ngx.ERR, cjson.encode(res))


ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10003,"error":"sign not given"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送不存在的sign请求，测试完毕')


end




do   --发送不存在的client_id请求
ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")

local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="sign=111"})


local code = res.status
local data = trim(res.body)

ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10005,"error":"client_id not given"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送不存在的client_id请求，测试完毕')

end





do   --发送无效的client_id请求

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")

local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="sign=111&client_id=aaa"})

local code = res.status
local data = trim(res.body)


ngx.say("code == 401 : "..tostring(assert(code==401)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10006,"error":"client_id not Authorize"}'

ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送无效的client_id请求，测试完毕')


end



do   --使用GET方式发送


ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_GET})

local code = res.status
local data = trim(res.body)

ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10010,"error":"method not allowed"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('使用GET方式发送，测试完毕')



end



do   --发送错误的sign签名

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")

local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body="sign=111&client_id=test1"})

local code = res.status
local data = trim(res.body)


ngx.say("code == 401 : "..tostring(assert(code==401)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10004,"error":"invalid sign"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('发送错误的sign签名，测试完毕')


end


do   --转发ip地址
ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_FORM_STR})

local code = res.status
local data = trim(res.body)

ngx.say("code == 503 or 200 : "..tostring(assert(code==503 or code==200)))
ngx.say('转发ip地址，测试完毕')

end



do   --使用json发送数据
ngx.req.set_header("Content-Type", "application/json")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_JSON_STR})

local code = res.status
local data = trim(res.body)

--ngx.log(ngx.ERR, cjson.encode(res))

ngx.say("code == 503 or 200 : "..tostring(assert(code==503 or code==200)))
ngx.say('使用json发送数据，测试完毕')

end


do   --错误的json发送数据

ngx.req.set_header("Content-Type", "application/json")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_JSON_STR.."12312312"})

local code = res.status
local data = trim(res.body)

ngx.log(ngx.ERR, cjson.encode(res))


ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10013,"error":"param error"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('错误的json发送数据，测试完毕')

end



do   --错误的x-www-form发送数据

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture(DEFAULT_URL,{method=ngx.HTTP_POST, body=DEFAULT_JSON_STR})

local code = res.status
local data = trim(res.body)

ngx.log(ngx.ERR, cjson.encode(res))


ngx.say("code == 400 : "..tostring(assert(code==400)))
local str = '{"result":false,"request":"\\/api\\/Messages\\/SendSms\\/","error_code":-10003,"error":"sign not given"}'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('错误的x-www-form发送数据，测试完毕')

end


do   --重建缓存

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture("/rebuild",{method=ngx.HTTP_GET})

local code = res.status
local data = trim(res.body)


ngx.say("code == 200 : "..tostring(assert(code==200)))
local str = 'rebuild cache success'
ngx.say('data == '.. str ..' : ' .. tostring(assert(data == str)))
ngx.say('重建缓存，测试完毕')

end


do   --后端服务器

ngx.req.set_header("Content-Type", "application/x-www-form-urlencoded")
local res = ngx.location.capture("/status",{method=ngx.HTTP_GET})

local code = res.status
local data = trim(res.body)


ngx.say("code == 200 : "..tostring(assert(code==200)))
assert(data ~= "")
ngx.say('后端服务器状态，测试完毕')

end

ngx.say('所有测试完毕')
ngx.exit(200)



