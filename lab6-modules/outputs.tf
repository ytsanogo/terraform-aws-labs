output "web_public_ip" {
  value = module.ec2_web.public_ip
}

output "web_instance_id" {
  value = module.ec2_web.instance_id
}
