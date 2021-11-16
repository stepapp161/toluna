
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
          "type": bind,
          "source": ./config/,
          "target": prometheus.yml /etc/prometheus
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
        matcher             = "200"
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
