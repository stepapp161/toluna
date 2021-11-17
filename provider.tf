terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
    aws = {
      version = "~> 2.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Pulls the image
resource "docker_image" "latest" {
  name = "rancher/hello-world:latest"
}

provider "aws" {
  region  = "us-east-2" 
}

