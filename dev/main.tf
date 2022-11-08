terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

data "digitalocean_ssh_key" "benny-ssh-key" {
  name = "benny-ssh"
}

data "digitalocean_project" "lab-project" {
  name = "benny-test"
}

# Create a new tag
resource "digitalocean_tag" "do-tag" {
  name = "Web"
}

# Create a new VPC
resource "digitalocean_vpc" "web-vpc" {
  name     = "4640-labs2"
  region   = var.region
}

# Create a new Web Droplet in the sfo3 region
resource "digitalocean_droplet" "web" {
  image    = "rockylinux-9-x64"
  count    = var.droplet_count
  name     = "web-${count.index + 1}"
  tags     = [digitalocean_tag.do-tag.id]
  region   = var.region
  size     = "s-1vcpu-512mb-10gb"
  ssh_keys = [data.digitalocean_ssh_key.benny-ssh-key.id]
  vpc_uuid = digitalocean_vpc.web-vpc.id

# if it have to delete it will create one before delete make sure the services is always running
  lifecycle {
     create_before_destroy = true
  }
}

# add new web-1 droplet to existing 4640_labs project
resource "digitalocean_project_resources" "project_attach" {
  project = data.digitalocean_project.lab-project.id
  resources = flatten([ digitalocean_droplet.web.*.urn ])
}

resource "digitalocean_loadbalancer" "public" {
  name   = "loadbalancer-1"
  region = var.region

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }
  droplet_tag = "Web"
  vpc_uuid = digitalocean_vpc.web-vpc.id
}

output "server_ip" {
    value = digitalocean_droplet.web.*.ipv4_address
}
