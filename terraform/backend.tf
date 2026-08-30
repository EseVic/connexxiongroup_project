terraform {
  backend "s3" {
    bucket  = "connexxiongroup"
    key     = "connexxiongroup/eks/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}