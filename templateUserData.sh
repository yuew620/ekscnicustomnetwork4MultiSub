MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
set -ex

# user input area start

# set the node group name every time when you create a new node group
varnodegroup="ng_xxx"

# plase set the AZ node cidr and corresponding eniconfig name for all AZ
declare -A myMap=(["172.31.0.0/20"]="ap-southeast-1c-4" ["172.31.16.0/20"]="ap-southeast-1b-4" ["172.31.32.0/20"]="ap-southeast-1a-4")

# set cluster info once , copy these value from automated node group template
B64_CLUSTER_CA=LS0tXXXXXXXS0tLS0K
API_SERVER_URL=https://35XXXXXXXXXX50.gr7.ap-southeast-1.eks.amazonaws.com
K8S_CLUSTER_DNS_IP=10.100.0.10

# user input area end

# get node primary ip
my_ip=$(ip route get $K8S_CLUSTER_DNS_IP | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')

# function of finding out which az the node belong to
function isIPbelongCidr
{
ip=$1
cidr=$2
max=`ipcalc -mbn $cidr |grep 'BROADCAST='|awk -F 'BROADCAST=' '{print $2}'`
min=`ipcalc -mbn $cidr |grep 'NETWORK='|awk -F 'NETWORK=' '{print $2}'`
MIN=`echo $min|awk -F"." '{printf"%.0f\n",$1*256*256*256+$2*256*256+$3*256+$4}'`
MAX=`echo $max|awk -F"." '{printf"%.0f\n",$1*256*256*256+$2*256*256+$3*256+$4}'`
IPvalue=`echo $ip|awk -F"." '{printf"%.0f\n",$1*256*256*256+$2*256*256+$3*256+$4}'`
if [ "$IPvalue" -ge "$MIN" ] && [ "$IPvalue" -le "$MAX" ]
then
echo "1"
return 1
else
echo "0"
return 0
fi
}

# get the eni config name
vareniconfig="NONE"
for key in ${!myMap[*]};do
echo $key
echo ${myMap[$key]}
if [ $(isIPbelongCidr "$my_ip" $key) -gt 0 ]
then
vareniconfig=${myMap[$key]}
break
fi
done

#set eniconf to node label
if [ $vareniconfig != "NONE" ]
then
/etc/eks/bootstrap.sh eksworkshop-eksctl --kubelet-extra-args "--node-labels=k8s.amazonaws.com/eniConfig=$vareniconfig,eks.amazonaws.com/nodegroup=$varnodegroup" --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL --dns-cluster-ip $K8S_CLUSTER_DNS_IP
#echo "end bootstrap"  >> /tmp/tmp20231020.txt
fi

#echo "test var" >> /tmp/tmp20231020.txt
#echo "my_ip is $my_ip" >> /tmp/tmp20231020.txt
#echo "vareniconfig is $vareniconfig" >> /tmp/tmp20231020.txt
#echo "varnodegroup is $varnodegroup" >> /tmp/tmp20231020.txt

--//--