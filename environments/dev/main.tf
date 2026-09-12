terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "devsecops-lab-bos-2026-dev"
    key            = "static-site/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
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

locals { 

  # Traduce el nombre real del workspace a un "alias" para nombrar recursos. 

  # El workspace "default" (el que ya tiene el bucket de dev del Lab 5) 

  # se sigue llamando "dev" a efectos de nomenclatura. 

  workspace_aliases = { 

    default = "dev" 

  } 

  environment_name = lookup(local.workspace_aliases, terraform.workspace, terraform.workspace) 

  

  environment_settings = { 

    dev     = { tags = { Criticidad = "baja" } } 

    staging = { tags = { Criticidad = "media" } } 

    prod    = { tags = { Criticidad = "alta" } } 

  } 

} 

module "site" { 
  source          = "../../modules/static-site" 
  bucket_name     = "devsecops-lab-${local.environment_name}-2026-bos" 
  index_file_path = "${path.module}/../../website/index.html" 
  environment     = local.environment_name 
  tags            = local.environment_settings[local.environment_name].tags 
} 
