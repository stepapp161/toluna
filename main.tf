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
  name = "hello-world:latest"
}

provider "aws" {
  region  = "us-east-2" 
}


# Reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Reference to our default subnets
resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "us-east-2b"
}


resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster" # Name of cluster
}

resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my-first-task" # Name of first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-first-task",
      "image": "hello-world",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is a  Fargate requirement
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_service" "my_first_service" {
  name            = "my-first-service"                             # Name of first service
  cluster         = "${aws_ecs_cluster.my_cluster.id}"             # Reference of created Cluster
  task_definition = "${aws_ecs_task_definition.my_first_task.arn}" # Reference of task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 2 # Number of containers to deploy


  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Reference our target group
    container_name   = "${aws_ecs_task_definition.my_first_task.family}"
    container_port   = 8080 # Specify the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
    assign_public_ip = true # Provide our containers with public IPs
    security_groups  = ["${aws_security_group.my_first_service.id}"]
      }
}


resource "aws_alb" "application_load_balancer" {
  name               = "test-lb-tf" # Name of load balancer
  load_balancer_type = "application"
  subnets = [ # Reference of default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
 }


resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = "80"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # Reference the default VPC
  depends_on  = [aws_alb.application_load_balancer]
  health_check {
    path = "/sample/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # Reference our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Reference our target group
  }
}
