
resource "docker_image" "ubuntu" {
  name = "bitnami/prometheus:latest"
}

resource "aws_ecs_task_definition" "prometheus_task" {
  family                   = "prometheus_task" # Name of first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "prometheus_task",
      "image": "bitnami/prometheus",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 9090,
          "hostPort": 9090
        }
      ],
      "volumes": [
        {
          "type": "bind",
          "source": "./config/",
          "target": "prometheus.yml /etc/prometheus"
        }
       ],
      "memory": 512,
      "cpu": 256,
      "networks": "apod"
    }
   ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is a  Fargate requirement
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}


resource "aws_ecs_service" "prometheus_service" {
  name            = "prometheus-service"                             # Name of prometheus service
  cluster         = "${aws_ecs_cluster.my_cluster.id}"             # Reference of created Cluster
  task_definition = "${aws_ecs_task_definition.prometheus_task.arn}" # Reference of task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 2 # Number of containers to deploy


  load_balancer {
    target_group_arn = "${aws_alb_target_group.demo_alb_target_group_ip_ecs_prometheus.arn}" # Reference our target group
    container_name   = "${aws_ecs_task_definition.prometheus_task.family}"
    container_port   = 9090 # Specify the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
    assign_public_ip = true # Provide our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"]
      }
}



#resource "aws_alb" "prometheus_load_balancer" {
#  name               = "prometheus" # Name of load balancer
 # load_balancer_type = "application"
  #subnets = [ # Reference of default subnets
   # "${aws_default_subnet.default_subnet_a.id}",
    #"${aws_default_subnet.default_subnet_b.id}"
  #]
  #security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
 #}


 
resource "aws_alb_target_group" "demo_alb_target_group_ip_ecs_prometheus" {
    name                 = "prometheus-tg"
    port                 = "80"
    protocol             = "HTTP"
    vpc_id      = "${aws_default_vpc.default_vpc.id}"
    deregistration_delay = 5
    target_type          = "ip"
    depends_on           = [aws_alb.application_load_balancer]

    lifecycle {
        create_before_destroy = true
    }

    health_check {
        healthy_threshold   = "2"
        unhealthy_threshold = "2"
        interval            = "5"
        matcher             = "200,301"
        path                = "/graph"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = "3"
    }

}


resource "aws_alb_listener" "demo_alb_listener_ecs_prometheus_front_end_http" {
   load_balancer_arn = "${aws_alb.application_load_balancer.arn}"
    port              = "90"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_alb_target_group.demo_alb_target_group_ip_ecs_prometheus.arn}"
        type             = "forward"
    }
}
