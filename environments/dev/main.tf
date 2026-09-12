terraform { 
  required_version = ">= 1.5.0" 
  required_providers { 
    aws = { 
      source  = "hashicorp/aws" 
      version = "~> 5.0" 
    } 
  }

  # required_version = ">= 1.10.0"

  # # Estado remoto: el .tfstate vive en S3, no en el runner efímero de
  # # GitHub Actions. Sin esto cada push arranca con estado vacío e intenta
  # # recrear el bucket, fallando con BucketAlreadyOwnedByYou.
  # # use_lockfile activa el bloqueo nativo de S3 (no requiere DynamoDB).
  # backend "s3" {
  #   bucket       = "devsecops-lab-bos-2026-tfstate"
  #   key          = "lab3-4/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }

  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #     version = "~> 5.0"
  #   }
  # } 
} 

provider "aws" { 
  region = "us-east-1" 
} 

module "site" { 
  source           = "../../modules/static-site" 
  bucket_name      = var.bucket_name 
  index_file_path  = "${path.module}/../../website/index.html" 
  environment      = "dev" 
  tags = { 
    Equipo = "DevSecOps" 
  } 
}