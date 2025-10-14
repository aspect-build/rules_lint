resource "aws_subnet" "example" {
  vpc_id            = var.vpc_id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "aspect-rules-lint-example"
  }
}
