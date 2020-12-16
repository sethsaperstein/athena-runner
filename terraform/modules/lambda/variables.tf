variable "bucket" {
    type = string
}

variable "s3_key" {
    type = string
}

variable "s3_object_version" {
    type = string
}

variable "name" {
    type = string
}

variable "timeout" {
    type = number
    default = 900
}

variable "handler" {
    type = string
}

variable "env_vars" {
    type = map(string)
    default = {}
}
