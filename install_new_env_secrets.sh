#!/usr/bin/env bash

# Step 1: Taint the Bucket & env file object
terraform taint module.ecs.aws_s3_object.django-secrets
terraform taint module.ecs.aws_s3_bucket.backend_secrets

# Step 2: Create a targeted infrastructure plan 
terraform plan -var-file=terraform.tfvars -out="./.plans/main.tfplan" 

# Step 3: Apply the infrastructure plan
read -e -p "Apply the Terraform plan? [Y/N] " YN
[[ $YN == "n" || $YN == "N" || $YN == "" ]] && exit 0
terraform apply "./.plans/main.tfplan"
