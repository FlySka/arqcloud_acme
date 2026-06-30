export AWS_DEFAULT_REGION=us-east-1

# ── 1) VPC ──
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=infra-viva-vpc}]' \
  --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# ── 2) Subredes ──
PUB_A=$(aws ec2 create-subnet  --vpc-id $VPC_ID --cidr-block 10.0.1.0/24  --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
PUB_B=$(aws ec2 create-subnet  --vpc-id $VPC_ID --cidr-block 10.0.2.0/24  --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)
APP_A=$(aws ec2 create-subnet  --vpc-id $VPC_ID --cidr-block 10.0.11.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
DB_A=$(aws ec2 create-subnet   --vpc-id $VPC_ID --cidr-block 10.0.21.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
DB_B=$(aws ec2 create-subnet   --vpc-id $VPC_ID --cidr-block 10.0.22.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)
aws ec2 modify-subnet-attribute --subnet-id $PUB_A --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_B --map-public-ip-on-launch

# ── 3) Internet Gateway + ruta pública ──
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
RT_PUB=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT_PUB --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $PUB_A
aws ec2 associate-route-table --route-table-id $RT_PUB --subnet-id $PUB_B

# ── 4) Tabla de rutas privada (sin salida aún) ──
RT_PRIV=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id $RT_PRIV --subnet-id $APP_A

# ── 5) Security Groups ──
ALB_SG=$(aws ec2 create-security-group --group-name alb-sg --description "ALB publico"  --vpc-id $VPC_ID --query 'GroupId' --output text)
APP_SG=$(aws ec2 create-security-group --group-name app-sg --description "App privada"   --vpc-id $VPC_ID --query 'GroupId' --output text)
NAT_SG=$(aws ec2 create-security-group --group-name nat-sg --description "NAT instance"  --vpc-id $VPC_ID --query 'GroupId' --output text)
DB_SG=$(aws ec2 create-security-group  --group-name db-sg  --description "RDS privada"   --vpc-id $VPC_ID --query 'GroupId' --output text)
# Regla L5 #1: Internet -> ALB:80
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
# Regla L5 #2: ALB -> App:80 (por referencia de SG)
aws ec2 authorize-security-group-ingress --group-id $APP_SG --protocol tcp --port 80 --source-group $ALB_SG
# (infra) la app usa el NAT
aws ec2 authorize-security-group-ingress --group-id $NAT_SG --protocol -1 --cidr 10.0.0.0/16
# (L2) App -> RDS:5432
aws ec2 authorize-security-group-ingress --group-id $DB_SG  --protocol tcp --port 5432 --source-group $APP_SG

# ── 6) NAT instance (Free Tier) + ruta privada ──
AMI=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query 'Parameter.Value' --output text)
NAT_ID=$(aws ec2 run-instances --image-id $AMI --instance-type t2.micro \
  --subnet-id $PUB_A --security-group-ids $NAT_SG --associate-public-ip-address \
  --user-data '#!/bin/bash
sysctl -w net.ipv4.ip_forward=1
IFACE=$(ip route | awk "/default/{print \$5}")
iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE' \
  --query 'Instances[0].InstanceId' --output text)
aws ec2 modify-instance-attribute --instance-id $NAT_ID --no-source-dest-check
aws ec2 wait instance-running --instance-ids $NAT_ID
aws ec2 create-route --route-table-id $RT_PRIV --destination-cidr-block 0.0.0.0/0 --instance-id $NAT_ID

# ── 7) Gateway Endpoints (gratis) para S3 y DynamoDB ──
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.s3       --route-table-ids $RT_PRIV
aws ec2 create-vpc-endpoint --vpc-id $VPC_ID --vpc-endpoint-type Gateway \
  --service-name com.amazonaws.us-east-1.dynamodb --route-table-ids $RT_PRIV

# ── 8) NACL personalizada en subred privada App (reglas L5 #3 y #4) ──
NACL=$(aws ec2 create-network-acl --vpc-id $VPC_ID --query 'NetworkAcl.NetworkAclId' --output text)
aws ec2 create-network-acl-entry --network-acl-id $NACL --rule-number 100 \
  --protocol tcp --port-range From=80,To=80 --cidr-block 10.0.0.0/16 --rule-action allow
aws ec2 create-network-acl-entry --network-acl-id $NACL --rule-number 100 --egress \
  --protocol tcp --port-range From=1024,To=65535 --cidr-block 10.0.0.0/16 --rule-action allow
ASSOC=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$APP_A \
  --query 'NetworkAcls[0].Associations[?SubnetId==`'$APP_A'`].NetworkAclAssociationId' --output text)
aws ec2 replace-network-acl-association --association-id $ASSOC --network-acl-id $NACL

# ── 9) DB subnet group (lo consume la L2 al crear RDS) ──
aws rds create-db-subnet-group --db-subnet-group-name infra-viva-db-subnets \
  --db-subnet-group-description "Subredes privadas para RDS Multi-AZ" \
  --subnet-ids $DB_A $DB_B

# ── 10) Application Load Balancer + target group + listener ──
ALB_ARN=$(aws elbv2 create-load-balancer --name infra-viva-alb --type application --scheme internet-facing \
  --subnets $PUB_A $PUB_B --security-groups $ALB_SG --query 'LoadBalancers[0].LoadBalancerArn' --output text)
TG_ARN=$(aws elbv2 create-target-group --name infra-viva-tg --protocol HTTP --port 80 \
  --vpc-id $VPC_ID --target-type instance --health-check-path / --query 'TargetGroups[0].TargetGroupArn' --output text)
aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

echo "ALB DNS: $(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --query 'LoadBalancers[0].DNSName' --output text)"
