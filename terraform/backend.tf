terraform {
  backend "s3" {
    bucket         = "task-3-41-tf-state-k9"
    key            = "task-3-49-cicd/terraform.tfstate"
    region         = "ap-south-1"
   
    dynamodb_table = "task-3-41-tf-lock"
    use_lockfile   = true

  }
}