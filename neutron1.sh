export srvpasswd=OuRvW8mWVoELWT
openstack user create --domain default --project service --password $srvpasswd neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking service" network
export controller=cloud.hackdv.com
openstack endpoint create --region RegionOne network public https://$controller:9696
openstack endpoint create --region RegionOne network internal https://$controller:9696
openstack endpoint create --region RegionOne network admin https://$controller:9696
cat > neutron.sql << EOF
create database neutron_ml2; 
grant all privileges on neutron_ml2.* to neutron@'localhost' identified by 'OuRvW8mWVoELWT'; 
grant all privileges on neutron_ml2.* to neutron@'%' identified by 'OuRvW8mWVoELWT'; 
flush privileges;
exit
EOF
mysql -u root -p < neutron.sql
dnf --enablerepo=centos-openstack-antelope,epel,crb -y install openstack-neutron openstack-neutron-ml2 ovn-2021-central openstack-neutron-ovn-metadata-agent ovn-2021-host
mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.org
cat > /etc/neutron/neutron.conf << EOF
[DEFAULT]
bind_host = 127.0.0.1
bind_port = 9696
core_plugin = ml2
service_plugins = ovn-router
auth_strategy = keystone
state_path = /var/lib/neutron
allow_overlapping_ips = True
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
# RabbitMQ connection info
transport_url = rabbit://openstack:OuRvW8mWVoELWT@cloud.hackdv.com

# Keystone auth info
[keystone_authtoken]
www_authenticate_uri = https://cloud.hackdv.com:5000
auth_url = https://cloud.hackdv.com:5000
memcached_servers = localhost:11211
auth_type = password
project_domain_name = default
user_domain_name = default
project_name = service
username = neutron
password = OuRvW8mWVoELWT
# if using self-signed certs on httpd Keystone, turn to [true]
insecure = false

# MariaDB connection info
[database]
connection = mysql+pymysql://neutron:password@cloud.hackdv.com/neutron_ml2

# Nova connection info
[nova]
auth_url = https://cloud.hackdv.com:5000
auth_type = password
project_domain_name = default
user_domain_name = default
region_name = RegionOne
project_name = service
username = nova
password = OuRvW8mWVoELWT
# if using self-signed certs on httpd Keystone, turn to [true]
insecure = false

[oslo_concurrency]
lock_path = $state_path/tmp
EOF
chmod 640 /etc/neutron/neutron.conf
chgrp neutron /etc/neutron/neutron.conf
mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.org
cat > /etc/neutron/plugins/ml2/ml2_conf.ini << EOF
[DEFAULT]
debug = false

[ml2]
type_drivers = flat,geneve
tenant_network_types = geneve
mechanism_drivers = ovn
extension_drivers = port_security
overlay_ip_version = 4

[ml2_type_geneve]
vni_ranges = 1:65536
max_header_size = 38

[ml2_type_flat]
flat_networks = *

[securitygroup]
enable_security_group = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

[ovn]
ovn_nb_connection = tcp:10.0.0.30:6641
ovn_sb_connection = tcp:10.0.0.30:6642
ovn_l3_scheduler = leastloaded
ovn_metadata_enabled = True
EOF
chmod 640 /etc/neutron/plugins/ml2/ml2_conf.ini
chgrp neutron /etc/neutron/plugins/ml2/ml2_conf.ini
firewall-cmd --add-port=9696/tcp
firewall-cmd --runtime-to-permanent

