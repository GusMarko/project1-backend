data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = "mg-terraform-state-storage"
    key = "project1-networking/terraform.tfstate"
    region = "${var.aws_region}"
  }
}