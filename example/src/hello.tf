resource "aws_subnet" "private_subnet_us_east_2a" {
  cidr_block        = "10.0.128.0/20"
  vpc_id            = aws_vpc.aspect_ci_vpc.id
  availability_zone = "us-east-2a"
  tags = {
    Name = "aspect-ci-subnet-private1-us-east-2a"
  }
}

# These show the tfsec warning regarding permissive access policies and access grants:
#
# Result #1 HIGH IAM policy document uses wildcarded action 's3:Get*'
# ────────────────────────────────────────────────────────────────────────────────
#   hello.tf:13-15
# ────────────────────────────────────────────────────────────────────────────────
#    10    data "aws_iam_policy_document" "bucket" {
#    11      statement {
#    12        effect = "Allow"
#    13  ┌     actions = [
#    14  │       "s3:Get*",
#    15  └     ]
#    16        resources = [
#    17          "*",
#    18        ]
#    ..
# ────────────────────────────────────────────────────────────────────────────────
#           ID aws-iam-no-policy-wildcards
#       Impact Overly permissive policies may grant access to sensitive resources
#   Resolution Specify the exact permissions required, and to which resources they should apply instead of using wildcards.
#
#   More Information
#   - https://aquasecurity.github.io/tfsec/v1.28.10/checks/aws/iam/no-policy-wildcards/
#   - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
#
data "aws_iam_policy_document" "bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:Get*",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "policy"
  policy      = data.aws_iam_policy_document.bucket.json
}
