variable "project_id" {
  type = string
  default = "jnorthcott2022"
}

variable "environment_lable" {
    type = string
    default = "development"
}

variable "owner_label"{
    type = string
    default = "professional-services"
}

variable "user_label" {
  type = string
  default = "jnorthcott"
}

variable "region" {
  type = string
  default = "us-east1"
}

variable "cluster_count" {
    type = number
    default = 1
}

variable "cluster_base_name" {
    type = string
    default = "jnorthcott-demo"
}

variable "initial_node_count" {
    type = number
    default = 3
}