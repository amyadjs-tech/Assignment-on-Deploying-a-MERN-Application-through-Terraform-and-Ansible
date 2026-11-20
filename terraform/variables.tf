variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "travelmemory"
}

variable "my_ip" {
  type        = string
  description = "Your public IPv4 address with /32 CIDR"
}

variable "public_key_path" {
  type        = string
  description = "Absolute path to your SSH public key"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}
