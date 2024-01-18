resource "aws_ecr_repository" "hello-world-service" {
  name                 = "hello-world-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}