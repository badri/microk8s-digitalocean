terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.28.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.5.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
}
