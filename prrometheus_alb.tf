
resource "aws_alb_target_group" "demo_alb_target_group_ip_ecs_prometheus" {
    name                 = "prometheus-tg"
    port                 = "${var.prometheus_container_host_port}"
    protocol             = "HTTP"
    vpc_id      = "${aws_default_vpc.default_vpc.id}"
    deregistration_delay = 5
    target_type          = "ip"
    depends_on           = ["aws_alb.application_load_balancer"]

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
    port              = "80"
    protocol          = "HTTP"

    default_action {
        target_group_arn = "${aws_alb_target_group.demo_alb_target_group_ip_ecs_prometheus.arn}"
        type             = "forward"
    }
}