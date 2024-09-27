output "local_key_name" {
  value = "${data.aws_key_pair.main.key_name}.ppk"
}