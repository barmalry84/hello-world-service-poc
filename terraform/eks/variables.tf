variable "region" {
  description = "Region where the VPC will be created"
  default     = "eu-west-1"
}

variable "cidr_base" {
  description = "IPv4 VPC range"
  default     = "10.1.0.0/16"
}
variable "private_subnets" {
  description = "List of CIDR ranges for the private subnets"
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "public_subnets" {
  description = "List of CIDR ranges for the public subnets"
  default     = ["10.1.4.0/24", "10.1.5.0/24", "10.1.6.0/24"]
}
