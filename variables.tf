variable "region" {
  type        = string
  description = "region"
}

variable "cluster_name" {
  type        = string
  description = "cluster_name"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs in the existing VPC"
  type        = list(string)
}


variable "replica" {
  type = string
  default = "1"
}

variable "enable_logging" {
  type = string
  #default = "yes"
  description = " Enable Logging ? Type yes or No :- "
}

variable "enable_ssl" {
  description = "Enable SSL : true or false"
  type        = bool
  #default = false
}

variable "email" {
  type = string
  #default = "prakharsingh1932003@gmai.com"

}

variable "domain_name" {
  description = "Enter your domain name"
  type        = string
  #default = "prakhar-devops.com"
}

variable "use_docker_auth" {
  description = "Do you want to use Docker authentication? (true/false)"
  type        = bool
  #default     = no
}

variable "docker_username" {
  description = "Enter your Docker Hub username"
  type        = string
  #default     = "prakhar0819"
}

variable "docker_password" {
  description = "Enter your Docker Hub password"
  type        = string
  sensitive   = true
  #default     = ""
}
