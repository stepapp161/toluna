resource "aws_security_group" "service_security_group" {
    security_groups = "${aws_security_group.load_balancer_security_group.id}"
}

resource "aws_security_group" "load_balancer_security_group" {

}
