terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Estado remoto: el .tfstate vive en S3, no en el runner efímero de
  # GitHub Actions. La key es exclusiva de este repo (lab 10) para no pisar
  # el estado de devsecops-pipeline-lab ni de devsecops-pipeline-lab-7 / lab-8 / lab-9.
  # use_lockfile activa el bloqueo nativo de S3 (no requiere DynamoDB).
  backend "s3" {
    bucket       = "devsecops-lab-bos-2026-tfstate"
    key          = "lab10/static-site/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
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
  bucket_name     = "devsecops-lab10-${local.environment_name}-2026-bos" 
  index_file_path = "${path.module}/../../website/index.html" 
  environment     = local.environment_name 
  tags            = local.environment_settings[local.environment_name].tags 
} 
