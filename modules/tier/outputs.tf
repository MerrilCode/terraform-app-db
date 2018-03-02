output "subnet_cidr_block" {
  value = "${var.cidr_block}"
}

output "priv_ip" {
    value = "${aws_instance.app-merril.*.private_ip[0]}"
}

output "id" {
  value = "${aws_instance.app-merril.*.id}"
}

output "subnet" {
  value = "${aws_subnet.app-merril.id}"
}

output "security_app" {
   value = "${aws_security_group.app-merril.id}"
 } 