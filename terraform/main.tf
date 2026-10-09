#S3 bucket
resource "aws_s3_bucket" "data" {
  bucket = "gbfs-tf-toronto"

  force_destroy = true #lets `terraform destroy` delete the bucket even if it has files in it
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#CloudWAtch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
    name = "/aws/lambda/gbfs-tf-collector"  #name should be the same as the lambda func name
    retention_in_days = 30
}

#Lambda execution role
#an IAM role needs two things: who is allowed to use the role (the trust policy) and what can they do (the permissions policy)
resource "aws_iam_role" "lambda" {
    name = "gbfs-tf-lambda-role"

    #trust policy: only the lambda service can use this role
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

#log policy; each run writes into a log stream inside a log group
resource "aws_iam_role_policy" "lambda_logs" {
    name = "write-logs"
    role = aws_iam_role.lambda.id 

    policy = jsonencode({
        Version: "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
            Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
        }]
    })
}

#allow lambda to uplaod file and nothing else 
resource "aws_iam_role_policy" "lambda_s3_put" {
    name = "s3-put-raw"
    role = aws_iam_role.lambda.id 

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = "s3:PutObject"
            Resource = "${aws_s3_bucket.data.arn}/raw/*" #limit the uploads into the raw/ folder 
        }]
    })
}

#Lambda Function 
resource "aws_lambda_function" "collector" {
    function_name = "gbfs-tf-collector"
    role = aws_iam_role.lambda.arn 
    handler = "lambda_function.lambda_handler"
    runtime = "python3.14"
    filename = "lambda.zip"
    source_code_hash = filebase64sha256("lambda.zip") #should the .py/function change, terraform should know
    memory_size = 128
    timeout = 15

    environment {
        variables = {
            BUCKET_NAME = aws_s3_bucket.data.bucket
        }
    }

    depends_on = [
        aws_cloudwatch_log_group.lambda, 
        aws_iam_role_policy.lambda_logs,
    ]
}

