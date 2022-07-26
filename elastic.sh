apt install default-jre
apt-get install apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
apt-get update 
apt-get install elasticsearch

echo "Enter: <cluster.name> <node.name> <[node.role, node.role]>"
read clusterName nodeName roles
echo "cluster.name: $clusterName
node.name: $nodeName
node.roles: $roles
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
bootstrap.memory_lock: true
network.host: 0.0.0.0
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl:
  enabled: true
  keystore.path: certs/http.p12
xpack.security.transport.ssl:
  enabled: true
  verification_mode: certificate
  keystore.path: certs/transport.p12
  truststore.path: certs/transport.p12
http.host: 0.0.0.0
transport.host: 0.0.0.0" > /etc/elasticsearch/elasticsearch.yml

echo "Enter number for JVM ram allocation: "
read ram
echo "-Xms${ram}g
-Xmx${ram}g" > /etc/elasticsearch/jvm.options.d/jvm.options

echo "vm.max_map_count=262144" > /etc/sysctl.conf
sed -i '10i LimitMEMLOCK=infinity' /usr/lib/systemd/system/elasticsearch.service

echo "Is this the first node: y/n"
read input

if [ $input = "y" ]; then
    echo "cluster.initial_master_nodes: [es01]" >> /etc/elasticsearch/elasticsearch.yml
    systemctl daemon-reload
    systemctl enable elasticsearch
    systemctl start elasticsearch
    PASS=$(/usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic)
    KIB=$(/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana)
    NODE=$(/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node)
    echo "${PASS}"
    echo "Kibana Token: ${KIB}"
    echo "Node Enrollement Token: ${NODE}"
else
    echo "Enter Enrollement Token: "
    read token
    /usr/share/elasticsearch/bin/elasticsearch-reconfigure-node --enrollment-token ${token}
    systemctl daemon-reload
    systemctl enable elasticsearch
    systemctl start elasticsearch
fi