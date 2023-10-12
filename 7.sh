export srvpasswd=OuRvW8mWVoELWT
mkdir -p /mnt/kvm/images
openstack user create --domain default --project service --password $srvpasswd nova
openstack role add --project service --user nova admin
openstack user create --domain default --project service --password $srvpasswd placement
openstack role add --project service --user placement admin
openstack service create --name nova --description "OpenStack Compute service" compute
openstack service create --name placement --description "OpenStack Compute Placement service" placement
export controller=cloud.hackdv.com	
openstack endpoint create --region RegionOne compute public https://$controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal https://$controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin https://$controller:8774/v2.1
openstack endpoint create --region RegionOne placement public https://$controller:8778
openstack endpoint create --region RegionOne placement internal https://$controller:8778
openstack endpoint create --region RegionOne placement admin https://$controller:8778
cat > nova.sql << EOF
create database nova;
grant all privileges on nova.* to nova@'localhost' identified by 'OuRvW8mWVoELWT';
grant all privileges on nova.* to nova@'%' identified by 'OuRvW8mWVoELWT';
create database nova_api;
grant all privileges on nova_api.* to nova@'localhost' identified by 'OuRvW8mWVoELWT';
grant all privileges on nova_api.* to nova@'%' identified by 'OuRvW8mWVoELWT';
create database nova_cell0;
grant all privileges on nova_cell0.* to nova@'localhost' identified by 'OuRvW8mWVoELWT';
grant all privileges on nova_cell0.* to nova@'%' identified by 'OuRvW8mWVoELWT';
create database placement;
grant all privileges on placement.* to placement@'localhost' identified by 'OuRvW8mWVoELWT';
grant all privileges on placement.* to placement@'%' identified by 'OuRvW8mWVoELWT';
flush privileges; 
exit
EOF
mysql -u root -p < nova.sql
dnf --enablerepo=centos-openstack-antelope,epel,crb -y install openstack-nova openstack-placement-api
mv /etc/nova/nova.conf /etc/nova/nova.conf.org
cat > /etc/nova/nova.conf << EOF
[DEFAULT]
osapi_compute_listen = 127.0.0.1
osapi_compute_listen_port = 8774
metadata_listen = 127.0.0.1
metadata_listen_port = 8775
state_path = /var/lib/nova
enabled_apis = osapi_compute,metadata
log_dir = /var/log/nova
# RabbitMQ connection info
transport_url = rabbit://openstack:OuRvW8mWVoELWT@cloud.hackdv.com

[api]
auth_strategy = keystone

[vnc]
enabled = True
novncproxy_host = 127.0.0.1
novncproxy_port = 6080
novncproxy_base_url = https://cloud.hackdv.com:6080/vnc_auto.html

# Glance connection info
[glance]
api_servers = https://cloud.hackdv.com:9292

[oslo_concurrency]
lock_path = $state_path/tmp

# MariaDB connection info
[api_database]
connection = mysql+pymysql://nova:OuRvW8mWVoELWT@cloud.hackdv.com/nova_api

[database]
connection = mysql+pymysql://nova:OuRvW8mWVoELWT@cloud.hackdv.com/nova

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = https://cloud.hackdv.com:5000
auth_url = https://cloud.hackdv.com:5000
memcached_servers = localhost:11211
auth_type = OuRvW8mWVoELWT
project_domain_name = default
user_domain_name = default
project_name = service
username = nova
password = OuRvW8mWVoELWT
# if using self-signed certs on httpd Keystone, turn to [true]
insecure = false

[placement]
auth_url = https://cloud.hackdv.com:5000
os_region_name = RegionOne
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = OuRvW8mWVoELWT
# if using self-signed certs on httpd Keystone, turn to [true]
insecure = false

[wsgi]
api_paste_config = /etc/nova/api-paste.ini
EOF
chmod 640 /etc/nova/nova.conf
chgrp nova /etc/nova/nova.conf
mv /etc/placement/placement.conf /etc/placement/placement.conf.org
cat > /etc/placement/placement.conf << EOF
[DEFAULT]
debug = false

[api]
auth_strategy = keystone

[keystone_authtoken]
www_authenticate_uri = https://cloud.hackdv.com:5000
auth_url = https://cloud.hackdv.com:5000
memcached_servers = localhost:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = placement
password = OuRvW8mWVoELWT
# if using self-signed certs on httpd Keystone, turn to [true]
insecure = false

[placement_database]
connection = mysql+pymysql://placement:OuRvW8mWVoELWT@cloud.hackdv.com/placement
EOF
chmod 640 /etc/placement/placement.conf
chgrp placement /etc/placement/placement.conf
firewall-cmd --add-port={6080/tcp,6081/tcp,6082/tcp,8774/tcp,8775/tcp,8778/tcp}
firewall-cmd --runtime-to-permanent
