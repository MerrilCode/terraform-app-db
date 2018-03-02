provider "aws" {
  region="eu-central-1"
}

resource "aws_vpc" "app-merril" {
  cidr_block       = "10.10.0.0/16"
  enable_dns_hostnames = true

  tags {
    Name = "app-merril"
  }
}

resource "aws_internet_gateway" "app-merril" {
  vpc_id = "${aws_vpc.app-merril.id}"

  tags {
    Name = "app-merril"
  }
}

resource "aws_route_table" "app-merril" {
  vpc_id = "${aws_vpc.app-merril.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.app-merril.id}"
  }

  tags {
    Name = "app-merril"
  }
}

resource "aws_elb" "app-merril" {
  name = "app-merril-lb"
  # availability_zones = ["eu-central-1a", "eu-central-1b","eu-central-1c" ]
  subnets = ["${module.app-tier.subnet}"]
  security_groups = ["${module.app-tier.security_app}"]


  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 5
    timeout = 10
    target = "HTTP:80/"
    interval = 30 
  }

  instances = ["${module.app-tier.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "app-merril-terraform-elb"
  }

}

# resource "aws_s3_bucket" "app-merril" {
#   bucket = "app-merril"
# }


resource "aws_launch_configuration" "app-merril" {
  name_prefix   = "app-merril"
  image_id      = "ami-83afc3ec"
  instance_type = "t2.micro"
  user_data="${data.template_file.app_init.rendered}"
  security_groups = ["${module.app-tier.security_app}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app-merril" {
  name                 = "app-merril"
  launch_configuration = "${aws_launch_configuration.app-merril.name}"
  min_size             = 2
  max_size             = 3
  load_balancers       = ["${aws_elb.app-merril.name}"]
  vpc_zone_identifier  = ["${module.app-tier.subnet}"]
  lifecycle {
    create_before_destroy = true
  }

    tag {
    key = "Name"
    value = "app-merril"
    propagate_at_launch = true

  }


}

data "template_file" "app_init" {
  template = "${file("./scripts/app_user_data.sh")}"
  vars {
        db_ip = "${module.db-tier.priv_ip}"
    }
}



module "app-tier" {
  name="app-merril"
  source="./modules/tier"
  vpc_id="${aws_vpc.app-merril.id}"
  machine_count = 2
  route_table_id = "${aws_route_table.app-merril.id}"
  cidr_block="10.10.0.0/24"
  user_data="${data.template_file.app_init.rendered}"
  ami_id = "ami-83afc3ec"
  map_public_ip_on_launch = true
  ingress = [{
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = "0.0.0.0/0"
  }]
}

module "db-tier" {
  name="db-merril"
  source="./modules/tier"
  vpc_id="${aws_vpc.app-merril.id}"
  route_table_id = "${aws_vpc.app-merril.main_route_table_id}"
  cidr_block="10.10.1.0/24"
  user_data=""
  machine_count = 1
  ami_id = "ami-0d771062"
  ingress = [{
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    cidr_blocks = "${module.app-tier.subnet_cidr_block}"
  }]
}
