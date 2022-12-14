terraform {
  backend "gcs" {
    bucket = "veritru-dev-terraform-state"
    prefix = "terraform/demo/state"
  }
}
