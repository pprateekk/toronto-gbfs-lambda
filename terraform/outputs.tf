output "bucket_arn" {
  value = aws_s3_bucket.data.arn
}

output "function_arn" {
  value = aws_lambda_function.collector.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda.arn
}
