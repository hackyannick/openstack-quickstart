systemctl restart mariadb rabbitmq-server memcached nginx
systemctl enable mariadb rabbitmq-server memcached nginx
rabbitmqctl add_user openstack OuRvW8mWVoELWT
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
firewall-cmd --add-service={mysql,memcache}
firewall-cmd --add-port=5672/tcp
firewall-cmd --runtime-to-permanent
dnf --enablerepo=centos-openstack-antelope,epel -y install openstack-keystone python3-openstackclient httpd mod_ssl python3-mod_wsgi python3-oauth2client mod_ssl
