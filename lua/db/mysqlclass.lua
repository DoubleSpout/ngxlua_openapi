local mysql = require "resty.mysql"


local ERR_MYSQL_LIB = "could not open mysql library"
local ERR_MYSQL_DB = "could not open mysql database"
local ERR_MYSQL_ERROR = "mysql occur error"

Mysql_CLass = {
    host = "192.168.28.4",
    port = 3306,
    database = "openapi",
    user = "root",
    password = "123456",
    max_packet_size =  1024 * 1024
}



function Mysql_CLass:connect()
		
        local db, err = mysql:new()
        if not db then
	    ngx.log(ngx.ERR, "mysql library error " .. err) --出错记录错误日志
            return ngx.HTTP_INTERNAL_SERVER_ERROR, nil, ERR_MYSQL_LIB
        end

        db:set_timeout(1000) -- 1 sec

	local ok, err, errno, sqlstate = db:connect{
                   host = self.host,
                   port = self.port,
                   database = self.database,
                   user = self.user,
                   password = self.password,
                   max_packet_size = self.max_packet_size 
		}

	if not ok then
	      ngx.log(ngx.ERR, "mysql not connect: " .. err .. ": " .. errno .. ": ".. sqlstate .. ".") --出错记录错误日志
	      return ngx.HTTP_INTERNAL_SERVER_ERROR, nil, ERR_MYSQL_DB
        end

	return ngx.HTTP_OK, db, nil

end


function Mysql_CLass:query_api_service(db, uri)

	 local api_service_table = {}
	 local uri = string.lower(uri or "/")
	 

	 local l = string.len(uri)
	 local pos = string.find(uri, '/', -1)
	 if(l == pos) then
	    uri = uri:sub(1,l-1)
         end


	 local res, err, errno, sqlstate =
              db:query("select id,servicename,servicepath,httpmethod,verifytype,routerpath,serviceroleid from ApiServices where enable = 1 and servicepath = '".. uri .."'" )
         if not res then
              ngx.log(ngx.ERR, "bad result: " .. err .. ": " .. errno .. ": ".. sqlstate .. ".") --出错记录错误日志
              return ngx.HTTP_INTERNAL_SERVER_ERROR, nil, ERR_MYSQL_ERROR
         end
	 

	 if(#res == 0) then
	      return ngx.HTTP_NOT_FOUND, nil, "-10011"	
	 end

	 api_service_table = res[1]


	 if(api_service_table.serviceroleid == ngx.null) then
	      return ngx.HTTP_OK, api_service_table, nil
	 end

	 local res2, err, errno, sqlstate =
              db:query("SELECT name,apikey,ApiSecret from ApiUserRoleTag as a JOIN ApiUser as b ON a.ApiUserId = b.id where a.ServiceRoleId = " .. api_service_table.serviceroleid )
         if not res2 then
              ngx.log(ngx.ERR, "bad result: " .. err .. ": " .. errno .. ": ".. sqlstate .. ".") --出错记录错误日志
              return ngx.HTTP_INTERNAL_SERVER_ERROR, nil, ERR_MYSQL_ERROR
         end
	
	 api_service_table.apiuser = res2

	 return ngx.HTTP_OK, api_service_table, nil

end