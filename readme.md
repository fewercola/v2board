## 使用 Docker Compose 部署

```bash
git clone --depth 1 https://github.com/fewercola/v2board .
docker compose pull
docker compose run -it --rm v2board sh init.sh
docker compose up -d
```

> **注意：** 初始化完成后，请务必及时记录 **管理员密码** 和 **后台路径**。

---

## 使用 Docker Compose 更新 V2Board

```bash
docker compose run -it --rm v2board sh update.sh
docker compose pull
docker compose down
docker compose run -it --rm v2board php artisan v2board:update
docker compose up -d
```

---

## 宿主机 Nginx 配置示例

请根据你的实际域名、证书路径、站点目录等内容自行修改：

```nginx
server
{
    listen 443 ssl proxy_protocol;
    http2 on;
    server_name ***********;

    root /www/wwwroot/***********/public/;
    index index.php index.html index.htm default.php default.htm default.html;

    #CERT-APPLY-CHECK--START
    include /www/server/panel/vhost/nginx/well-known/***********.conf;
    #CERT-APPLY-CHECK--END
    include /www/server/panel/vhost/nginx/extension/***********/*.conf;

    #SSL-START
    #error_page 404/404.html;
    ssl_certificate    /www/server/panel/vhost/cert/***********/fullchain.pem;
    ssl_certificate_key    /www/server/panel/vhost/cert/***********/privkey.pem;
    ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_tickets on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    add_header Strict-Transport-Security "max-age=31536000";
    add_header Alt-Svc 'quic=":443"; h3=":443"; h3-29=":443"; h3-27=":443"; h3-25=":443"; h3-T050=":443"; h3-Q050=":443"; h3-Q049=":443"; h3-Q048=":443"; h3-Q046=":443"; h3-Q043=":443"';
    error_page 497 https://$host$request_uri;
    #SSL-END

    error_page 404 /404.html;

    # Gzip
    gzip on;
    gzip_static on;
    gzip_vary on;
    gzip_min_length 1k;
    gzip_comp_level 5;
    gzip_types
        text/plain
        text/css
        application/json
        application/javascript
        text/xml
        application/xml
        application/xml+rss
        text/javascript
        image/svg+xml;

    # real ip
    set_real_ip_from 127.0.0.1;
    set_real_ip_from ::1;
    real_ip_header proxy_protocol;
    real_ip_recursive on;

    # 清理缓存规则
    location ~ /purge(/.*)$ {
        proxy_cache_purge cache_one $host$1$is_args$args;
    }

    # 禁止访问敏感文件
    location ~ ^/(\.user\.ini|\.htaccess|\.git|\.env|\.svn|\.project|LICENSE|README\.md) {
        return 404;
    }

    # 证书验证
    location ^~ /.well-known/ {
        allow all;
    }

    if ($uri ~ "^/\.well-known/.*\.(php|jsp|py|js|css|lua|ts|go|zip|tar\.gz|rar|7z|sql|bak)$") {
        return 403;
    }

    location ~ \.php$ {
        try_files $uri =404;
        include fastcgi_params;

        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;

        # 容器内真实路径
        fastcgi_param SCRIPT_FILENAME /www/public$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT /www/public;

        fastcgi_read_timeout 300;
    }

    location /downloads {
    }

    # 普通请求：先找静态文件，否则走 6600 后端
    location / {
        try_files $uri $uri/ @backend;
    }

    location @backend {
        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_pass http://127.0.0.1:6600;
    }

    # 这些路径走 index.php
    location ~ ^/(config|manage|webhook|payment|order|theme)(/|$) {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    # 静态资源缓存
    location ~* \.(js|css)$ {
        expires 1h;
        log_not_found off;
        access_log off;
    }

    access_log  /www/wwwlogs/***********.log;
    error_log   /www/wwwlogs/***********.error.log;
}
```
