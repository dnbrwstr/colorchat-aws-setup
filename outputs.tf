output "master_config" {
  value = "${template_file.master_config.rendered}"
}

output "gateway_ip" {
  value = "${aws_instance.gateway.public_ip}"
}