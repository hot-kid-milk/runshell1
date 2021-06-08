#!/usr/bin/env bash
cntFile=".showcnt.txt"
epFile="epFile.txt"
if [ ! -f $cntFile ]; then

fi
if [ $# == 1 ]; then
if [ $1 == "resetcnt" ]; then
echo "0" > $cntFile
fi
fi
ep=`cat $epFile`
tCnt=`cat $cntFile`
let tCnt++
echo $tCnt > $cntFile
echo "    这是第 $tCnt 次创建节点"
echo "    若需更改endpoint，请自行修改epFile.txt"
cat>node${tCnt}.yaml<<EOF
api-addr: :$((534+${tCnt}*1000))
#config: /root/node${tCnt}.yaml
data-dir: /var/lib/bee/node${tCnt}
cache-capacity: "2000000"
block-time: "15"
debug-api-addr: :$((634+${tCnt}*1000))
debug-api-enable: true
p2p-addr: :$((734+${tCnt}*1000))
password-file: /var/lib/bee/password
swap-initial-deposit: "10000000000000000"
verbosity: 5
db-open-files-limit: 10000
swap-endpoint: ${ep}
full-node: true
EOF
cat>startbee${tCnt}.sh<<EOF
#!/bin/bash
portNum=\$(netstat -tunlp|grep $((634+${tCnt}*1000)) |wc -l)
if [ \${portNum} -eq 0 ]; then 
    sudo nohup bee start --config /root/node${tCnt}.yaml   > /root/nohup${tCnt}.out 2>&1 &
fi
EOF
chmod 777 startbee${tCnt}.sh
cp cashout.sh cashout${tCnt}.sh
sed -i "s/1635/$((634+${tCnt}*1000))/g" cashout${tCnt}.sh
echo "* */1 * * * root /root/cashout${tCnt}.sh cashout-all 5 >> /root/cashout${tCnt}.log 2>&1 & " >> /etc/crontab 
echo "*/3 * * * * root  /root/startbee${tCnt}.sh >> /root/startbee${tCnt}.log 2>&1 & "  >> /etc/crontab 
sudo nohup bee start --config /root/node${tCnt}.yaml   > /root/nohup${tCnt}.out 2>&1 &
sleep 30
tar -czvpf /home/$ip-node${tCnt}-keys.tar.gz  /var/lib/bee/node${tCnt}/ --exclude /var/lib/bee/node*/localstore --exclude /var/lib/bee/node*/statestore
tar -czvpf /home$ip-bee${tCnt}-password.tar.gz  /var/lib/bee/ --exclude /var/lib/bee/node*
/usr/local/bin/aws s3 cp /home/$ip-node${tCnt}-keys.tar.gz s3://node-backup-01/
/usr/local/bin/aws s3 cp /home/$ip-bee${tCnt}-password.tar.gz  s3://node-backup-01/
cat /var/lib/bee/node1/keys/swarm.key| jq -r '.address'
ip=`curl icanhazip.com`
addr=`cat /var/lib/bee/node${tCnt}/keys/swarm.key| jq -r '.address'`
curl http://100.24.126.135:8000/bee/address/ip=$ip,node=${tCnt},address=0x$addr



