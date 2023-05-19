#!/bin/sh

until microk8s.status --wait-ready;
  do sleep 3; echo "waiting for worker status..";
done


if microk8s status | grep "datastore master nodes: 127.0.0.1:19001" > /dev/null 2>&1; then
  echo "adding ${main_node_ip} ip to CSR."
  sed -i 's@#MOREIPS@IP.99 = ${main_node_ip}\n#MOREIPS\n@g' /var/snap/microk8s/current/certs/csr.conf.template
  echo "done."
  sleep 10
  microk8s join ${main_node_ip}:25000/${cluster_token}
else
  echo "Join process already done. Nothing to do"
fi
