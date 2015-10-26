variable "vpc_cidr" {
  default = "10.128.0.0/16"
}
variable "subnet_cidr_a" {
  default = "10.128.0.0/17"
}
variable "subnet_cidr_b" {
  default = "10.128.128.0/17"
}

# Create VPC
resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
    Name = "kubernetes"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "public_a" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${var.subnet_cidr_a}"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  availability_zone = "us-east-1a"
  tags {
    Name = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${var.subnet_cidr_b}"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.default"]
  availability_zone = "us-east-1b"
  tags {
    Name = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id = "${aws_subnet.public_a.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public_b" {
  subnet_id = "${aws_subnet.public_b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_security_group" "default" {
  name = "kubernetes-default"
  vpc_id = "${aws_vpc.default.id}"

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_all_cluster" {
  type = "ingress"
  from_port = 0
  to_port = 65535
  protocol = "-1"
  source_security_group_id = "${aws_security_group.default.id}"
  security_group_id = "${aws_security_group.default.id}"
}

resource "aws_security_group" "ssh" {
  name = "kubernetes-ssh"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "web" {
  name = "kubernetes-web"
  vpc_id = "${aws_vpc.default.id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name = "color-rds-subnet"
  description = "Subnet for colorchat RDS"
  subnet_ids = ["${aws_subnet.public_a.id}", "${aws_subnet.public_b.id}"]
}

resource "aws_elasticache_subnet_group" "default" {
  name = "color-elasticache-subnet"
  description = "Subnet for colorchat elasticache"
  subnet_ids = ["${aws_subnet.public_a.id}", "${aws_subnet.public_b.id}"]
}