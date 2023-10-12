su -s /bin/bash placement -c "placement-manage db sync"
su -s /bin/bash nova -c "nova-manage api_db sync"
su -s /bin/bash nova -c "nova-manage cell_v2 map_cell0"
su -s /bin/bash nova -c "nova-manage db sync"
su -s /bin/bash nova -c "nova-manage cell_v2 create_cell --name cell1"
systemctl restart httpd nginx
systemctl enable --now openstack-nova-api openstack-nova-conductor openstack-nova-scheduler openstack-nova-novncproxy
chown placement. /var/log/placement/placement-api.log
openstack compute service list