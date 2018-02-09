output "subnet_cidr_block" {
  value = "${var.cidr_block}"
}

output "priv_ip" {
    value = "${aws_instance.app-merril.private_ip}"
}