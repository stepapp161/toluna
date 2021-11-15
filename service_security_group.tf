resource "aws_security_group" "service_security_group" {
  ingress {
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

egress {
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  ingress {
  }

  egress {
  }
}
