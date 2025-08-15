resource "random_id" "unique_suffix" {
  byte_length = 8
}

resource "aws_s3_bucket" "lambda_s3_bucket" {
  bucket = "invoice-bucket-${random_id.unique_suffix.hex}"

  tags = {
    Name        = "lambda_s3_bucket"
    Environment = "Dev"
  }
}


