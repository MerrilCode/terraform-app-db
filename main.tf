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
  route_table_id = "${aws_route_table.app-merril.id}"
  cidr_block="10.10.0.0/24"
  user_data="${data.template_file.app_init.rendered}"
  ami_id = "ami-927314fd"
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
  ami_id = "ami-0d771062"
  ingress = [{
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    cidr_blocks = "${module.app-tier.subnet_cidr_block}"
  }]
}
