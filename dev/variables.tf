variable "do_token" {}

#Set the default region to sfo3
variable "region" {
    type  = string
    default = "sfo3"
}

#Set the default droplet count
variable "droplet_count"{
    type = number
    default = 2
}