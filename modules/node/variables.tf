variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs in the existing VPC"
  type        = list(string)
}

variable "cluster_name" {
    type = string
    description = "cluster_name"
}