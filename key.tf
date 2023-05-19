resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "digitalocean_ssh_key" "microk8s" {
  name       = "Terraform microk8s"
  public_key = tls_private_key.rsa_4096.public_key_openssh
}
