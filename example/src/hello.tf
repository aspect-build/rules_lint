resource "aws_subnet" "private_subnet_us_east_2a" {
  cidr_block        = "10.0.128.0/20"
  vpc_id            = aws_vpc.aspect_ci_vpc.id
  availability_zone = "us-east-2a"
  tags = {
    Name = "aspect-ci-subnet-private1-us-east-2a"
  }
}
