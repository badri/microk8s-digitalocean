# IP of node
output "microk8s_node_ip" {
  value = digitalocean_droplet.microk8s-node.0.ipv4_address
}
# key
output "ssh_key" {
  value = tls_private_key.rsa_4096.public_key_openssh
}
