su -s /bin/bash keystone -c "keystone-manage db_sync"
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
export controller=cloud.hackdv.com
keystone-manage bootstrap --bootstrap-password OuRvW8mWVoELWT \
--bootstrap-admin-url https://$controller:5000/v3/ \
--bootstrap-internal-url https://$controller:5000/v3/ \
--bootstrap-public-url https://$controller:5000/v3/ \
--bootstrap-region-id RegionOne
firewall-cmd --add-port=5000/tcp
firewall-cmd --runtime-to-permanent
