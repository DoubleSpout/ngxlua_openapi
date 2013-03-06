#! /bin/sh
PATH=/usr/local/openresty/nginx/sbin:$PATH;
export PATH;
chmod 777 `pwd`/ -c conf/nginx_main_debug.conf;
nginx -p `pwd`/ -c conf/nginx_main_debug.conf;
