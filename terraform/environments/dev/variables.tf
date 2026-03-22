variable "environment" {
  type        = string
  description = "Environment name"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name for EC2 instances"
}

variable "my_ip" {
  type        = string
  description = "Your public IP for SSH access"
}
