resource "digitalocean_volume" "microk8s-worker-node" {
  region      = var.region
  count       = var.node_count
  name        = "microk8s-worker-fs-${count.index}"
  size        = var.worker_node_disksize
  description = "A volume to attach to the worker"
}

resource "digitalocean_droplet" "microk8s-worker-node" {
  image  = var.os_image
  name   = "microk8s-worker-${var.cluster_name}-${count.index}"
  region = var.region
  size   = var.worker_node_size
  count  = var.worker_node_count

  tags = [
    digitalocean_tag.microk8s-worker.id
  ]

  ssh_keys = [
    digitalocean_ssh_key.microk8s.fingerprint,
  ]
  user_data  = templatefile("${path.module}/templates/node.yaml.tmpl", { microk8s_channel = var.microk8s_channel })
  volume_ids = [element(digitalocean_volume.microk8s-worker-node.*.id, count.index)]

}

# Tag to label nodes
resource "digitalocean_tag" "microk8s-worker" {
  name = "microk8s-worker-${var.cluster_name}"
}


resource "null_resource" "join_workers" {
  count      = var.worker_node_count
  depends_on = [null_resource.setup_tokens, null_resource.join_nodes]
  triggers = {
    rerun = random_id.cluster_token.hex
  }
  connection {
    host        = element(digitalocean_droplet.microk8s-worker-node.*.ipv4_address, count.index)
    user        = "root"
    type        = "ssh"
    private_key = tls_private_key.rsa_4096.private_key_openssh
    timeout     = "20m"
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "while [[ $(cat /tmp/current_joining_worker_node.txt) != \"${count.index}\" ]]; do echo \"${count.index} is waiting...\";sleep 5;done"
  }

  provisioner "file" {
    content = templatefile("${path.module}/templates/join-worker.sh",
      {
        cluster_token = random_id.cluster_token.hex
        main_node_ip  = digitalocean_droplet.microk8s-node[0].ipv4_address
    })
    destination = "/usr/local/bin/join-worker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sh /usr/local/bin/join-worker.sh"
    ]
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    command     = "echo \"${count.index + 1}\" > /tmp/current_joining_worker_node.txt"
  }
}
