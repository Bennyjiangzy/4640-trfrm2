# 4640-trfrm1
This is the tutorial about how to use terraform and ansible to deploy resources in Digital Ocean

## Install Terraform 
First step is to install terraform. You can follow the official website and choose your OS system docs to install it

```
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
```

After you follow the docs, you should be able to see commands by type:
```
terraform -help
```

## Create some stuffs in your Digital Ocean
- API keys for terraform to access DO
- SSH-KEYS
- Project

### API keys
- Login to your account
- Click **API** in left bar at bottom
- Click **Generate New Token** in the middle
- Copy the token to a .env file in the root folder
     
    ```
    export TF_VAR_do_token=<Your-Token>
    ```
- Source the file make sure you can print it in your teminal by echo
### SSH-KEYS
- Login to your account
- Click **Settings** in left bar at bottom
- Click **Security** in the middle
- Click **Add SSH Key**
- Upload the PKI in your computer
<!-- end of the list -->
This key will be "pulled" and "attach" to the resources. We will use it in terrform and ssh to the resources we deployed

### Project
- Login to your account
- Click **New Project** in left bar at top
<!-- end of the list -->
This project will be "pulled" and we will "attach" resources to this project.

## Terraform
In the main.tf folder, Run cmd below to initialize:
```
terraform init
```
Terraform cheat sheet
```
terraform validate # check syntax
terraform plan # check running process without actual deploy
terraform apply # actual deploy but need to type "yes"
terraform destroy # destroy the resources in current apply but need to type "yes"
```
Actual code in main.tf
```
# Provider is digitallocean
terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Get ssh-key info in DO
data "digitalocean_ssh_key" "benny-ssh-key" {
  name = "benny-ssh" #  actual name in DO
}

# Get project info in DO
data "digitalocean_project" "lab-project" {
  name = "benny-test" #  actual name in DO
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

#output the vm ip we deployed after terraform apply
output "server_ip" {
    value = digitalocean_droplet.web.ipv4_address
}
```
After you successfully running the terraform apply. Copy the ip address in the **"server_ip"** section, run a ssh cmd by using the ssh-key you called in the terraform to that ip. Check if this works.

## Ansible
Make sure you create an access token in digital ocean and export it in your environment the var name should be **DO_API_TOKEN=token**

After you create running the terraform, go to the **mgmt** folder and run **ansible-inventory --graph** you should be able to see the vm we created group with *webservs*.

Then running **ansible-playbook nignx.yml -u root** to install nginx in two vm and verify it by access the load balancer ip. You should be able to see the nginx page.