ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable --now httpd
cat > ~/keystonerc << EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=OuRvW8mWVoELWT
export OS_AUTH_URL=https://cloud.hackdv.com:5000
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='[\u@\h \W(keystone)]\$ '
EOF
chmod 600 ~/keystonerc
source ~/keystonerc
echo "source ~/keystonerc " >> ~/.bash_profile
openstack project create --domain default --description "Service Project" service
openstack project list
openstack user create --domain default --project service --password OuRvW8mWVoELWT glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image
export controller=cloud.hackdv.com
openstack endpoint create --region RegionOne image public https://$controller:9292
openstack endpoint create --region RegionOne image internal https://$controller:9292
openstack endpoint create --region RegionOne image admin https://$controller:9292
cat > glancedbprep.sql << EOF
create database glance;
grant all privileges on glance.* to glance@'localhost' identified by 'OuRvW8mWVoELWT';
grant all privileges on glance.* to glance@'%' identified by 'OuRvW8mWVoELWT'; 
flush privileges; 
exit
EOF
mysql -u root -p < glancedbprep.sql
dnf --enablerepo=centos-openstack-antelope,epel,crb -y install openstack-glance
mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.org
cat > /etc/glance/glance-api.conf << EOF
[DEFAULT]
bind_host = 127.0.0.1
# RabbitMQ connection info
transport_url = rabbit://openstack:OuRvW8mWVoELWT@localhost

[glance_store]
stores = file,http
default_store = file
filesystem_store_datadir = /var/lib/glance/images/

[database]
# MariaDB connection info
connection = mysql+pymysql://glance:OuRvW8mWVoELWT@cloud.hackdv.com/glance

# keystone auth info
[keystone_authtoken]
www_authenticate_uri = https://cloud.hackdv.com:5000
auth_url = https://cloud.hackdv.com:5000
memcached_servers = localhost:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = glance
password = OuRvW8mWVoELWT
# if using self-signed certs on httpd for Keystone, turn to [true]
insecure = false

[paste_deploy]
flavor = keystone
EOF
chmod 640 /etc/glance/glance-api.conf
chgrp glance /etc/glance/glance-api.conf
su -s /bin/bash glance -c "glance-manage db_sync"
systemctl enable --now openstack-glance-api
