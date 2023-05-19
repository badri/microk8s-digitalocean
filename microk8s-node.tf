resource "random_id" "cluster_token" {
  byte_length = 16
}

resource "digitalocean_volume" "microk8s-node" {
  region      = var.region
  count       = var.node_count
  name        = "microk8s-node-fs-${count.index}"
  size        = var.node_disksize
  description = "A volume to attach to the worker.  Can be used for Rook Ceph"
}

resource "digitalocean_droplet" "microk8s-node" {
  image  = var.os_image
  name   = "microk8s-node-${var.cluster_name}-${count.index}"
  region = var.region
  size   = var.node_size
  count  = var.node_count

  tags = [
    digitalocean_tag.microk8s-node.id
  ]

  ssh_keys = [
    digitalocean_ssh_key.microk8s.fingerprint,
  ]
  user_data  = templatefile("${path.module}/templates/node.yaml.tmpl", { microk8s_channel = var.microk8s_channel })
  volume_ids = [element(digitalocean_volume.microk8s-node.*.id, count.index)]
}

# Tag to label nodes
resource "digitalocean_tag" "microk8s-node" {
  name = "microk8s-node-${var.cluster_name}"
}

resource "null_resource" "setup_tokens" {
  depends_on = [null_resource.provision_node_hosts_file]
  triggers = {
    rerun = random_id.cluster_token.hex
  }
  connection {
    host        = digitalocean_droplet.microk8s-node[0].ipv4_address
    user        = "root"
    type        = "ssh"
    private_key = tls_private_key.rsa_4096.private_key_openssh
    timeout     = "2m"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = <<EOT
        echo "1" > /tmp/current_joining_node.txt
        echo "0" > /tmp/current_joining_worker_node.txt
        EOT
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/add-node.sh",
      {
        main_node_ip              = digitalocean_droplet.microk8s-node[0].ipv4_address
        cluster_token             = random_id.cluster_token.hex
        cluster_token_ttl_seconds = var.cluster_token_ttl_seconds
    })
    destination = "/usr/local/bin/add-node.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sh /usr/local/bin/add-node.sh",
      "/snap/bin/microk8s.config -l > /client.config",
      "echo 'updating kubeconfig'; sed -i 's/127.0.0.1:16443/${digitalocean_droplet.microk8s-node[0].ipv4_address}:16443/g' /client.config",
    ]
  }
}


resource "null_resource" "join_nodes" {
  count      = var.node_count - 1 < 1 ? 0 : var.node_count - 1
  depends_on = [null_resource.setup_tokens]
  triggers = {
    rerun = random_id.cluster_token.hex
  }
  connection {
    host        = element(digitalocean_droplet.microk8s-node.*.ipv4_address, count.index + 1)
    user        = "root"
    type        = "ssh"
    private_key = tls_private_key.rsa_4096.private_key_openssh
    timeout     = "20m"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "while [[ $(cat /tmp/current_joining_node.txt) != \"${count.index + 1}\" ]]; do echo \"${count.index + 1} is waiting...\";sleep 5;done"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/join.sh",
      {
        cluster_token = random_id.cluster_token.hex
        main_node_ip  = digitalocean_droplet.microk8s-node[0].ipv4_address
    })
    destination = "/usr/local/bin/join.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sh /usr/local/bin/join.sh"
    ]
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "echo \"${count.index + 2}\" > /tmp/current_joining_node.txt"
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.rsa_4096.private_key_openssh
  filename        = "${path.cwd}/private-key"
  file_permission = "0400"
}


resource "null_resource" "get_kubeconfig" {
  depends_on = [null_resource.setup_tokens]

  provisioner "local-exec" {
    command = "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${path.cwd}/private-key root@${digitalocean_droplet.microk8s-node[0].ipv4_address}:/client.config ${path.cwd}"
  }
}
