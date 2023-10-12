cat >> /etc/nginx/nginx.conf << EOF
stream {
    upstream glance-api {
        server 127.0.0.1:9292;
    }
    server {
        listen 10.0.200.4:9292 ssl;
        proxy_pass glance-api;
    }
    ssl_certificate "/opt/ssl/cert.pem";
    ssl_certificate_key "/opt/ssl/privkey.pem";
}
EOF
systemctl restart nginx
firewall-cmd --add-port=9292/tcp
firewall-cmd --runtime-to-permanent
