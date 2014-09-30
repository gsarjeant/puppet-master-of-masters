mv /etc/hosts/ /tmp/hosts.orig
echo "127.0.0.1 localhost.localdomain localhost localhost4.localdomain4 localhost4" > /etc/hosts
echo "192.168.141.100 pe-master.example.vm pe-master" >> /etc/hosts
echo "192.168.141.101 pe-puppetdb.example.vm pe-puppetdb" >> /etc/hosts
echo "192.168.141.102 pe-console.example.vm pe-console" >> /etc/hosts
echo "192.168.141.100 pe-master.tenant.example.vm pe-master" >> /etc/hosts
echo "192.168.141.101 pe-puppetdb.tenant.example.vm pe-puppetdb" >> /etc/hosts
echo "192.168.141.102 pe-console.tenant.example.vm pe-console" >> /etc/hosts
