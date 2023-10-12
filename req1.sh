dnf -y install centos-release-openstack-antelope
sed -i -e "s/enabled=1/enabled=0/g" /etc/yum.repos.d/CentOS-OpenStack-antelope.repo
dnf --enablerepo=centos-openstack-antelope -y upgrade
dnf -y install mariadb-server rabbitmq-server memcached nginx-mod-stream
