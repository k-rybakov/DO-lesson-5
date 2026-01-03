# 1. ECR-репозиторій з авто-скануванням
resource "aws_ecr_repository" "this" {
  name = var.ecr_name

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name = var.ecr_name
  }
}

# 2. Політика доступу до репозиторію
data "aws_iam_policy_document" "ecr_repo_policy" {
  statement {
    sid = "AllowPullAll"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:ListImages"
    ]
    resources = [
      aws_ecr_repository.this.arn
    ]
  }
}