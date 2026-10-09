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

