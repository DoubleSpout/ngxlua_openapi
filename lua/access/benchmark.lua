local result = "测试机：<br/>" ..
"cpu：E5620  @ 2.40GHz （4个）<br/>"..
"men：8G<br/>"..
"测试用例1、500并发，500000个请求，压力测试命令：<br/>"..
"ab -n 500000 -c 500 -T 'Content-Type:application/json' -p /tmp/open_api_test.json  http://192.168.28.5/test/<br/>"..
"qps：8379.59<br/>"..
"cpu：55% (avg)<br/>"..
"mem：15MB (avg)<br/>"..
"<br/>"..
"<br/>"..
"测试用例2、100并发，500000个请求、压力测试命令：<br/>"..
"ab -n 500000 -c 100 -T 'Content-Type:application/json' -p /tmp/open_api_test.json  http://192.168.28.5/test/<br/>"..
"qps：7247.67<br/>"..
"cpu：50% (avg)<br/>"..
"mem：9MB (avg)<br/>"..
"<br/>"..
"<br/>"..
"测试用例3、1000并发，500000个请求、压力测试命令：<br/>"..
"ab -n 500000 -c 1000 -T 'Content-Type:application/json' -p /tmp/open_api_test.json  http://192.168.28.5/test/<br/>"..
"qps：8715.41<br/>"..
"cpu：60% (avg)<br/>"..
"mem：22MB (avg)<br/>"..
"<br/>"..
"<br/>"..
"测试工具：<br/>"..
"vmstat<br/>"..
"ab<br/>"..
"<br/>"..
"vmstat 1 > /tmp/filememory<br/>"





ngx.header["Content-Type"] = "text/html;charset=utf-8"

ngx.say(result)



























