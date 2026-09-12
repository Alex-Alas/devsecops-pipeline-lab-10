terraform {
  required_version = ">= 1.10.0"

  # Estado remoto: el .tfstate vive en S3, no en el runner efímero de
  # GitHub Actions. Sin esto cada push arranca con estado vacío e intenta
  # recrear el bucket, fallando con BucketAlreadyOwnedByYou.
  # use_lockfile activa el bloqueo nativo de S3 (no requiere DynamoDB).
  backend "s3" {
    bucket       = "devsecops-lab-bos-2026-tfstate"
    key          = "lab3-4/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  common_tags = merge( 
    { 
      Proyecto    = "DevSecOps-Lab" 
      Entorno     = var.environment 
      GestionadoPor = "Terraform" 
    }, 
    var.tags 
  ) 
}

resource "aws_s3_bucket" "site" { 
  bucket = var.bucket_name 
  tags   = local.common_tags 
} 

resource "aws_s3_bucket_public_access_block" "site" { 
  bucket                  = aws_s3_bucket.site.id 
  block_public_acls       = false 
  block_public_policy     = false 
  ignore_public_acls      = false 
  restrict_public_buckets = false 
} 

resource "aws_s3_bucket_website_configuration" "site" { 
  bucket = aws_s3_bucket.site.id 
  index_document { 
    suffix = "index.html" 
  } 
} 

resource "aws_s3_bucket_policy" "public_read" { 
  bucket     = aws_s3_bucket.site.id 
  depends_on = [aws_s3_bucket_public_access_block.site] 
  policy = jsonencode({ 
    Version = "2012-10-17" 
    Statement = [{ 
      Sid       = "PublicReadGetObject" 
      Effect    = "Allow" 
      Principal = "*" 
      Action    = "s3:GetObject" 
      Resource  = "${aws_s3_bucket.site.arn}/*" 
    }] 
  })
}

resource "aws_s3_object" "index" { 
  bucket       = aws_s3_bucket.site.id 
  key          = "index.html" 
  source       = var.index_file_path 
  content_type = "text/html" 
  etag         = filemd5(var.index_file_path) 
} 

# provider "aws" {
#   region = var.aws_region
# }

# resource "aws_s3_bucket" "site" {
#   bucket = var.bucket_name
#   tags = {
#     Proyecto = "DevSecOps-Lab3-4"
#     Entorno  = "laboratorio"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "site" {
#   bucket                  = aws_s3_bucket.site.id
#   block_public_acls       = false
#   block_public_policy     = false
#   ignore_public_acls      = false
#   restrict_public_buckets = false
# }

# resource "aws_s3_bucket_website_configuration" "site" {
#   bucket = aws_s3_bucket.site.id
#   index_document {
#     suffix = "index.html"
#   }
# }

# resource "aws_s3_bucket_policy" "public_read" {
#   bucket     = aws_s3_bucket.site.id
#   depends_on = [aws_s3_bucket_public_access_block.site]
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Sid       = "PublicReadGetObject"
#       Effect    = "Allow"
#       Principal = "*"
#       Action    = "s3:GetObject"
#       Resource  = "${aws_s3_bucket.site.arn}/*"
#     }]
#   })
# }

# resource "aws_s3_object" "index" {
#   bucket       = aws_s3_bucket.site.id
#   key          = "index.html"
#   source       = "${path.module}/website/index.html"
#   content_type = "text/html"
#   etag         = filemd5("${path.module}/website/index.html")
# }
