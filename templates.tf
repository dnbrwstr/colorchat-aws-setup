resource "template_file" "master_config" {
  filename = "${path.cwd}/cloud-config/compiled/master.yml"

  vars {
    cluster_name = "${var.cluster_name}"
    postgres_endpoint = "${aws_db_instance.default.endpoint}"
    postgres_db = "${aws_db_instance.default.name}"
    postgres_user = "${aws_db_instance.default.username}"
    postgres_password = "${aws_db_instance.default.password}"
    redis_endpoint = "${aws_elasticache_cluster.default.cache_nodes.0.address}:${aws_elasticache_cluster.default.port}"
    aws_access_key_id = "${var.aws_key}"
    aws_secret_access_key = "${var.aws_secret}"
    twilio_account_sid = "${var.twilio_account_sid}"
    twilio_auth_token = "${var.twilio_auth_token}"
    twilio_number = "${var.twilio_number}"
    parse_application_id = "${var.parse_application_id}"
    parse_rest_api_key = "${var.parse_rest_api_key}"
    datadog_api_key = "${var.datadog_api_key}"
  }
}
