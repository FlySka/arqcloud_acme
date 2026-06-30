output "ec2_alb_dns" {
  description = "URL pública del balanceador EC2 — pega en el navegador"
  value       = "http://${module.ec2_asg.alb_dns_name}"
}

output "ecs_alb_dns" {
  description = "URL pública del servicio ECS Fargate"
  value       = "http://${module.ecs_fargate.alb_dns_name}"
}

output "lambda_function_name" {
  description = "Nombre de la función Lambda"
  value       = module.lambda.function_name
}

output "lambda_api_url" {
  description = "URL del API Gateway que invoca Lambda"
  value       = module.lambda.api_url
}

output "escalabilidad_comando_ec2" {
  description = "Comando para probar escalabilidad EC2"
  value       = "ab -n 5000 -c 100 http://${module.ec2_asg.alb_dns_name}/"
}

output "escalabilidad_comando_lambda" {
  description = "Comando para probar escalabilidad Lambda"
  value       = "artillery quick --count 200 --num 50 ${module.lambda.api_url}"
}
