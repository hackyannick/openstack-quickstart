systemctl enable --now openvswitch
ovs-vsctl add-br br-int
ln -s /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugin.ini
su -s /bin/bash neutron -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head"
systemctl enable --now ovn-northd ovn-controller
ovn-nbctl set-connection ptcp:6641:10.0.0.30 -- set connection . inactivity_probe=60000
ovn-sbctl set-connection ptcp:6642:10.0.0.30 -- set connection . inactivity_probe=60000
ovs-vsctl set open . external-ids:ovn-remote=tcp:10.0.200.4:6642
ovs-vsctl set open . external-ids:ovn-encap-type=geneve
ovs-vsctl set open . external-ids:ovn-encap-ip=10.0.200.4
systemctl enable --now neutron-server neutron-ovn-metadata-agent
systemctl restart openstack-nova-api openstack-nova-compute nginx
openstack network agent list
ovs-vsctl add-br br-eno1
ovs-vsctl add-port br-eth1 eno1
ovs-vsctl set open . external-ids:ovn-bridge-mappings=physnet1:br-eno1
projectID=$(openstack project list | grep service | awk '{print $2}')
openstack network create --project $projectID \
--share --provider-network-type flat --provider-physical-network physnet1 sharednet1
openstack subnet create subnet1 --network sharednet1 \
--project $projectID --subnet-range 10.0.200.0/24 \
--allocation-pool start=10.0.0.49,end=10.0.200.254 \
--gateway 10.0.200.1 --dns-nameserver 10.0.200.1
openstack network list
openstack subnet list
openstack project create --domain default --description "Hack-DV Cloud" HKDVCLOUD
openstack user create --domain default --project HKDVCLOUD --password userpassword OuRvW8mWVoELWT
openstack role create CloudUser
openstack role add --project HKDVCLOUD --user yhack CloudUser
openstack flavor create --id 0 --vcpus 1 --ram 2048 --disk 10 m1.small
