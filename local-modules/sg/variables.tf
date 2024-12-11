variable "vpc_id" {
  description = "aws vpc id"
  type        = string
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "tags" {
  type = map(string)
}