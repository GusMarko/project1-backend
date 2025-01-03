variable "aws_region" {
     type = string
}

variable "access_key" {
 type = string
}

variable "secret_key" {
 type = string
}

variable "env" {
  description = "branch"
}


variable "image_uri" {
  description = "Pth to code image stored in ecr"
}

variable "client_id" {
  type = string
  description = "Credentials for Spotify"
}

variable "client_secret" {
  type = string
  description = "Credentials for Spotify"
}