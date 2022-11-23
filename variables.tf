variable "project_id" {
  type = string
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
}

variable "initial_node_count" {
    type = number
    default = 3
}
