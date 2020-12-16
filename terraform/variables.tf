variable "env_name" {
  type = string
}

variable "log_level" {
  type = string
}

variable "account_id" {
  type = string
}

variable "region" {
    type = string
}

variable "athena_runner_s3_object_version" {
  type = string
}

variable "athena_runner_s3_key" {
    type = string
}

variable "deploy_bucket_name" {
    type = string
}

variable "seconds_to_wait" {
    type = number
    default = 30
}
