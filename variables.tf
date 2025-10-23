variable "aws_region" {
  type = string
}

variable "eks_id" {
  description = "The identifier of the EKS cluster that hosts the microservices that need access to databases"
  type        = string
}

variable "eks_sg_id" {
  description = "The identifier of the EKS cluster's security group. We need this to configure network access to the databases"
  type        = string
}

variable "vpc_id" {
  description = "The identifier of the VPC that contains the microservices EKS cluster"
  type        = string
}

variable "subnet_a_id" {
  description = "Subnet A for the database instance"
  type        = string
}

variable "subnet_b_id" {
  description = "Subnet B for the database instance"
  type        = string
}

variable "env_name" {
  description = "The environment name - used for resource naming and tagging"
  type        = string
}

variable "mysql_user" {
  description = "The mysql user id that will be set for the RDS database instance"
  type        = string
  default     = "microservices"
}

variable "mysql_password" {
  description = "The mysql password that will be set for the RDS database instance"
  type        = string
}

variable "mysql_database" {
  description = "The name of the RDS database instance"
  type        = string
  default     = "microservices_db"
}

variable "route53_id" {
  description = "The ID of the Route 53 resource for this VPC. Needed so a DNS record for the RDS instance can be added."
  type        = string
}
