variable "aws_key" {}
variable "aws_secret" {}
variable "aws_region" {
  default = "us-east-1"
}
variable "aws_primary_availability_zone" {
  default = "us-east-1a"
}
variable "aws_secondary_availability_zone" {
  default = "us-east-1b"
}
variable "datadog_api_key" {}
variable "twilio_account_sid" {}
variable "twilio_auth_token" {}
variable "twilio_number" {}
variable "parse_application_id" {}
variable "parse_rest_api_key" {}
variable "cluster_name" {
  default = "kubernetes"
}
variable "coreos_image" {
  default = "ami-05783d60"
}

provider "aws" {
  access_key = "${var.aws_key}"
  secret_key = "${var.aws_secret}"
  region = "${var.aws_region}"
}

resource "aws_route53_record" "gateway-a" {
  zone_id = "Z2DQMJ6TC97SKM"
  name = "*.color"
  type = "A"
  ttl = 60
  records = ["${aws_instance.gateway.public_ip}"]
}

resource "aws_instance" "gateway" {
  instance_type = "t2.micro"
  ami = "${var.coreos_image}"
  key_name = "default"
  user_data = "${template_file.master_config.rendered}"
  subnet_id = "${aws_subnet.public_a.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}", "${aws_security_group.ssh.id}", "${aws_security_group.web.id}"]

  root_block_device {
    volume_type = "gp2"
    volume_size = 8
  }
}

resource "aws_db_parameter_group" "default" {
  name = "colorchat-postgres-default"
  family = "postgres9.4"
  description = "Colorchat postgres settings"
}

resource "aws_db_instance" "default" {
  identifier = "color-rds"
  allocated_storage = 5
  engine = "postgres"
  engine_version = "9.4.1"
  instance_class = "db.t2.micro"
  name = "colorchat"
  username = "postgres"
  password = "postgres"
  port = 5432
  db_subnet_group_name = "color-rds-subnet"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  parameter_group_name = "colorchat-postgres-default"
  depends_on = ["aws_db_subnet_group.default", "aws_db_parameter_group.default"]
}

resource "aws_elasticache_cluster" "default" {
  cluster_id = "colorchat"
  engine = "redis"
  node_type = "cache.t2.micro"
  port = 6379
  num_cache_nodes = 1
  subnet_group_name = "color-elasticache-subnet"
  security_group_ids = ["${aws_security_group.default.id}"]
  depends_on = ["aws_elasticache_subnet_group.default"]
}

resource "aws_ebs_volume" "rabbitmq_storage" {
  availability_zone = "${var.aws_primary_availability_zone}"
  size = 40
  tags {
    Name = "RabbitMQStorage"
  }
}

resource "aws_volume_attachment" "rabbitmq_storage_mount" {
  device_name = "/dev/xvdf"
  volume_id = "${aws_ebs_volume.rabbitmq_storage.id}"
  instance_id = "${aws_instance.gateway.id}"
}
