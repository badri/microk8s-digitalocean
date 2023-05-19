# DigitalOcean Terraform MicroK8s

**Verfied using terraform v1.4.6**

**Warning Reducing nodes still does not leave the cluster**

**Support for worker only node, which means it will not run control plane components such as the api-server, scheduler and controller manager, available from MicroK8s v1.22**

Bootstrap a Highly Available MicroK8s cluster in DigitalOcean with Terraform.

For example to bootstrap a 3 control plane nodes and 2 worker nodes cluster.

```hcl

module "microk8s" {
  source                       = "../"
  cluster_name                 = "lakshmi"
  node_count                   = "3"
  worker_node_count            = "2"
  os_image                     = "ubuntu-20-04-x64"
  node_size                    = "s-2vcpu-4gb"
  worker_node_size             = "s-4vcpu-8gb"
  node_disksize                = "30"
  region                       = "blr1"
  microk8s_channel             = "latest/stable"
  cluster_token_ttl_seconds    = 3600
}


```

| Fields                        | Description                              | Default values |
| ----------------------------- |:-----------------------------------------| -------------- |
| source                        | The source of the terraform module       | none
| node_count                    | The number of MicroK8s nodes to create   | 3
| os_image                      | DigitalOcean OS images.  <br/>To get the list OS images `doctl compute image list-distribution`| ubuntu-20-04-x64
| node_size                     | DigitalOcean droptlet sizes <br/> To get the list of droplet sizes `doctl compute size list`| s-4vcpu-8gb
| node_disksize                 | Additional volume to add to the droplet.  Size in GB| 50 |
| region                        | DigitalOcean region <br/> To get the list of regions `doctl compute region list`| sgp1
| dns_zone                      | The DNS zone representing your site.  Need to register your domain. | geeks.sg
| microk8s_channel              | Specify the MicroK8s channel to use.  Refer [here](https://snapcraft.io/microk8s)| stable
| cluster_token_ttl_seconds     | How long the token validity (in seconds)| 3600
| worker_node_size              | The worker node size example: `s-4vcpu-8gb` | s-4vcpu-8gb
| worker_node_count             | The number of MicroK8s worker nodes | 2
| worker_node_disksize          | Additional volume to add to the droplet.  Size in GB| 100 |


## DigitalOcean TF environment variables

You must have these environment variables present.

```shell

TF_VAR_digitalocean_token=<your DO access token>
```

## Creating the cluster

Simply run the `terraform plan` and then `terraform apply`


The module automatically downloads the kubeconfig file to your local machine in `client.config`
In order to access the Kubernetes cluster from your local machine, simply do `export KUBECONFIG=/<pwd>/client.config`

```bash
$ kubectl get nodes
NAME                        STATUS   ROLES    AGE   VERSION
microk8s-node-lakshmi-0     Ready    <none>   16m   v1.27.1
microk8s-node-lakshmi-1     Ready    <none>   14m   v1.27.1
microk8s-node-lakshmi-2     Ready    <none>   14m   v1.27.1
microk8s-worker-lakshmi-0   Ready    <none>   13m   v1.27.1
microk8s-worker-lakshmi-1   Ready    <none>   13m   v1.27.1
```

This will connect using the load balancer fronting the api servers.

## MicroK8s High Availability
It requires node counts to be greater than or equal to 3 to form a majority.  Each node can be a control plane, hence there is really no concept of control plane.

Check documentation on [MicroK8s Discuss HA](https://discuss.kubernetes.io/t/high-availability-ha/11731)


## Digitalocean attached volume

This terraform also creates and attach a volume to each droplet.  This will let you setup Rook + Ceph storage.  This way you can freely create volumes that you can share to your pods.
