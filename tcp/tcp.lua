
local sock = ngx.socket.tcp()
local host = "192.168.28.5"
local port = 8124
local ok, err = sock:connect(host, port)
if not ok then
    ngx.say("failed to connect to ".. host ..": ", err)
    return
end
ngx.say("successfully connected to ".. host)
sock:close()