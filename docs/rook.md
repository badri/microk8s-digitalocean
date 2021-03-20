# Rook / Ceph PersistentVolume

Rook manifests are located in the [Rook Manifests](../rook/cephfs/) directory.

In order to install rook, you need to perform the following:

On Master node, make sure that the kubernetes API Server allows privileged pods.

Go to the directory `/var/snap/microk8s/current/args`, check the file `kube-apiserver`.

Add `--allow-privileged=true` argument, sample below

```shell
--cert-dir=${SNAP_DATA}/certs
--service-cluster-ip-range=10.152.183.0/24
--authorization-mode=RBAC,Node
--basic-auth-file=${SNAP_DATA}/credentials/basic_auth.csv
--service-account-key-file=${SNAP_DATA}/certs/serviceaccount.key
--client-ca-file=${SNAP_DATA}/certs/ca.crt
--tls-cert-file=${SNAP_DATA}/certs/server.crt
--tls-private-key-file=${SNAP_DATA}/certs/server.key
--kubelet-client-certificate=${SNAP_DATA}/certs/server.crt
--kubelet-client-key=${SNAP_DATA}/certs/server.key
--secure-port=16443
--token-auth-file=${SNAP_DATA}/credentials/known_tokens.csv
--token-auth-file=${SNAP_DATA}/credentials/known_tokens.csv
--etcd-servers='https://127.0.0.1:12379'
--etcd-cafile=${SNAP_DATA}/certs/ca.crt
--etcd-certfile=${SNAP_DATA}/certs/server.crt
--etcd-keyfile=${SNAP_DATA}/certs/server.key
--insecure-port=0
--allow-privileged=true
```

```shell
kubectl apply -f rook/common.yaml
kubectl apply -f rook/operator.yaml

# Wait for the rook operator to become available
kubectl -n rook-ceph get pods
NAME                                                              READY   STATUS      RESTARTS   AGE
rook-ceph-operator-5c8c896d6c-889l7                               1/1     Running     5          32m
rook-discover-9cw89                                               1/1     Running     0          28m
rook-discover-wnzzf                                               1/1     Running     0          28m
rook-discover-wqc4p                                               1/1     Running     0          28m
```

Once you have these pods up and running, you can now start to create the `CephCluster`.

Creating the `CephCluster`, apply the [cluster.yaml](../rook/cluster.yaml)

`kubectl apply -f rook/cluster.yaml`

Once you apply that manifest, you should see these pods in the `rook-ceph` namespace.

```shell
NAME                                                              READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-bmtcb                                            3/3     Running     0          34m
csi-cephfsplugin-nlrkd                                            3/3     Running     0          34m
csi-cephfsplugin-provisioner-7b8fbf88b4-j8w5p                     4/4     Running     0          34m
csi-cephfsplugin-provisioner-7b8fbf88b4-rk4qd                     4/4     Running     0          34m
csi-cephfsplugin-zml4q                                            3/3     Running     0          34m
csi-rbdplugin-7fx5j                                               3/3     Running     0          34m
csi-rbdplugin-cbms4                                               3/3     Running     0          34m
csi-rbdplugin-provisioner-6b8b4d558c-6jfbh                        5/5     Running     0          34m
csi-rbdplugin-provisioner-6b8b4d558c-rtlqq                        5/5     Running     0          34m
csi-rbdplugin-t6s26                                               3/3     Running     0          34m
rook-ceph-crashcollector-10.130.17.47-f9b4496bf-sgnlt             1/1     Running     0          32m
rook-ceph-crashcollector-10.130.40.90-f8c7d77dc-vr49j             1/1     Running     0          29m
rook-ceph-crashcollector-microk8s-controller-cetacean-6c894kbbc   1/1     Running     0          29m
rook-ceph-mds-myfs-a-777bf8ffcb-fktwl                             1/1     Running     0          29m
rook-ceph-mds-myfs-b-84fd995775-dlwsl                             1/1     Running     0          29m
rook-ceph-mgr-a-589d8f9d64-n5qql                                  1/1     Running     0          33m
rook-ceph-mon-a-58689c7ffd-l8bbc                                  1/1     Running     0          33m
rook-ceph-operator-5c8c896d6c-889l7                               1/1     Running     5          39m
rook-ceph-osd-0-6b659fdc47-fqzm7                                  1/1     Running     0          32m
rook-ceph-osd-1-7bfbc46cff-46v8c                                  1/1     Running     0          32m
rook-ceph-osd-2-79695c7d56-tsk9t                                  1/1     Running     0          32m
rook-ceph-osd-prepare-10.130.17.47-c5lk9                          0/1     Completed   0          32m
rook-ceph-osd-prepare-10.130.40.90-ttgbr                          0/1     Completed   0          32m
rook-ceph-osd-prepare-microk8s-controller-cetacean-nl9qx          0/1     Completed   0          32m
rook-discover-9cw89                                               1/1     Running     0          35m
rook-discover-wnzzf                                               1/1     Running     0          35m
rook-discover-wqc4p                                               1/1     Running     0          35m
```

Now that you have the `CephCluster` up and running, you can now start to create your own filesystem on top of ceph.

The following example below will create a `CephFileSystem`.

```shell

kubectl apply -f rook/cephfs/myfs.yaml
kubectl apply -f rook/cephfs/storageclass.yaml
kubectl apply -f rook/cephfs/pvc.yaml
```

Finally you can now create a pod which can make use of the Ceph file system using the standard Kubernetes `PersistentVolumeClaim`
