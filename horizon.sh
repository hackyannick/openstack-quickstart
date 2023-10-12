dnf --enablerepo=centos-openstack-antelope,epel,crb -y install openstack-dashboard
firewall-cmd --add-service={http,https}
firewall-cmd --runtime-to-perman