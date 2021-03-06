
# Redirect all HTTP trafic to HTTPS

error_log  /home/hakon/tapcrate-errors  warn;

server {
    listen 80;
    listen [::]:80;

    server_name tapcrate.com www.tapcrate.com api.tapcrate.com www.api.tapcrate.com static.tapcrate.com www.static.tapcrate.com beta.tapcrate.com www.beta.tapcrate.com;

    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root /tmp/letsencrypt-auto/;
    }

    location = /.well-known/acme-challenge/ {
        return 404;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {

    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;

    include snippets/ssl-tapcrate.com.conf;
    include snippets/ssl-params.conf;

    server_name tapcrate.com www.tapcrate.com;

    root /home/jasper/tapcrate-web;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        include snippets/gzip.conf;
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    include snippets/ssl-api.tapcrate.com.conf;
    include snippets/ssl-params.conf;

    root /home/hakon/tapcrate-api;

    server_name api.tapcrate.com www.api.tapcrate.com;

    location / {
        include proxy_params;
        include snippets/gzip.conf;
        proxy_pass http://127.0.0.1:8080;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    include snippets/ssl-beta.tapcrate.com.conf;
    include snippets/ssl-params.conf;

    root /home/hakon/tapcrate-development-api;

    server_name beta.tapcrate.com www.beta.tapcrate.com;

    location / {
        include proxy_params;
        include snippets/gzip.conf;
        proxy_pass http://127.0.0.1:8081;
    }
}

proxy_cache_path /data/nginx/cache levels=1:2 keys_zone=static:10m inactive=60m use_temp_path=off max_size=4g;

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    include snippets/ssl-api.tapcrate.com.conf;
    include snippets/ssl-params.conf;

    root /home/hakon/tapcrate-api/Public;

    server_name static.tapcrate.com www.static.tapcrate.com;

    location / {
        include h5bp/basic.conf;

        tcp_nodelay on;
        keepalive_timeout 65;
        sendfile on;
        tcp_nopush on;
        sendfile_max_chunk 1m;

        include snippets/gzip.conf;

        proxy_cache static;
        try_files $uri =404;
    }
}
