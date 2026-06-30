# Orden: ELB → endpoints → NAT instance → DB subnet group → rutas/IGW → subredes → SG/NACL → VPC.
aws elbv2 delete-listener --listener-arn <LISTENER_ARN>
aws elbv2 delete-target-group --target-group-arn $TG_ARN
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
aws ec2 terminate-instances --instance-ids $NAT_ID
aws rds delete-db-subnet-group --db-subnet-group-name infra-viva-db-subnets
# ...borrar vpc-endpoints, route tables, detach/delete IGW, subredes, SG, NACL...
aws ec2 delete-vpc --vpc-id $VPC_ID
