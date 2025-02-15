# 1️⃣ Create an S3 Bucket
resource "aws_s3_bucket" "static_bucket" {
  bucket = "agusjulis3.sctp-sandbox.com"  # Change this to a unique bucket name
}

# 2️⃣ Configure Static Website Hosting
resource "aws_s3_bucket_public_access_block" "enable_public_access" {
  bucket = aws_s3_bucket.static_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3️⃣ Set S3 Bucket Policy for Public Read Access
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.static_bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.static_bucket.id}/*"
    }
  ]
}
POLICY
}

# 4️⃣ Upload Index.html
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.static_bucket.id

  index_document {
    suffix = "index.html"
  }
}

data "aws_route53_zone" "sctp_zone" {
  name = "sctp-sandbox.com"
}


# 5️⃣ Set Up Route 53 Record
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.sctp_zone.zone_id
  name    = "agusjulis3.sctp-sandbox.com" # Replace with the same bucket prefix
  type    = "A"

  alias {
    name                   = aws_s3_bucket_website_configuration.website.website_domain
    zone_id                = aws_s3_bucket.static_bucket.hosted_zone_id
    evaluate_target_health = true
  }
}

# 6 Clone git repo
resource "null_resource" "clone_git_repo" {
  provisioner "local-exec" {
    command = <<EOT
         git clone https://github.com/cloudacademy/static-website-example.git website_content
      aws s3 sync website_content s3://agusjulis3.sctp-sandbox.com --exclude "*.MD" --exclude ".git*" --delete
    EOT
  }
  
  # Ensures this runs after the S3 bucket is created
  depends_on = [aws_s3_bucket.static_bucket]
}

