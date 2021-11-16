# toluna
# Deploy An AWS ECS Web Server And Monitor With Prometheues

# Introduction

# Pre-requisites
Before we get started installing the stack on AWS.
* Ensure the latest version of terraform is installed
* Create an IAM role in AWS and attach the following Policies;
    *  AmazonEC2FullAccess 
    *  IAMFullAccess 
    *  ElasticLoadBalancingFullAccess 
    *  AmazonEC2ContainerRegistryFullAccess 
    *  AmazonECS_FullAccess 
    *  AmazonECSTaskExecutionRolePolicy 
    *  ElasticLoadBalancingReadOnly 
# Steps to run the provisioning in terraform
1. Clone the repo

git clone https://github.com/stepapp161/toluna.git 

2. Terraform initialize a working directory

terraform init

3. Terraform to create an execution plan

terraform plan

4. Terraform apply to provision in aws

terraform apply

# Result
Apply complete! Resources: 19 added, 0 changed, 0 destroyed.
