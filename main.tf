provider "aws" {
  region = var.aws_region
}

# Lookup the EKS cluster that we created for the Microservices
data "aws_eks_cluster" "microservice-cluster" {
  name = var.eks_id
}

# The RDS subnet group that points to the subnets we've declared above
resource "aws_db_subnet_group" "rds-subnet-group" {
  name       = "${var.env_name}-rds-subnet-group"
  subnet_ids = ["${var.subnet_a_id}", "${var.subnet_b_id}"]
}

# Create a security group to allow traffic from the EKS cluster
resource "aws_security_group" "db-security-group" {
  name        = "${var.env_name}-allow-eks-db"
  description = "Allow traffic from EKS manage workload"
  vpc_id      = var.vpc_id

  ingress {
    description = "All traffic from managed EKS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    #security_groups = data.aws_eks_cluster.microservice-cluster.vpc_config.0.security_group_ids
  }
}

# The default security group
data "aws_security_group" "default" {
  vpc_id = var.vpc_id
  name   = "default"
}

# Our RDS database instance
resource "aws_db_instance" "mysql-db" {
  allocated_storage = 20 # Free tier eligible
  storage_type      = "gp2"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro" # Free tier eligible
  # name              = var.mysql_database
  identifier = "microservices-mysql"

  username             = var.mysql_user
  password             = var.mysql_password
  parameter_group_name = "default.mysql8.0"

  # Free tier compatible settings
  max_allocated_storage = 20    # Prevent auto-scaling beyond free tier
  storage_encrypted     = false # Encryption not available in free tier
  multi_az              = false # Multi-AZ not available in free tier

  # Backup settings (reduce costs)
  backup_retention_period = 1             # Keep backups for 1 day only
  backup_window           = "03:00-04:00" # Off-peak hours
  maintenance_window      = "sun:04:00-sun:05:00"

  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.rds-subnet-group.name
  vpc_security_group_ids = [var.eks_sg_id]
}

# Elasticache subnet group
resource "aws_elasticache_subnet_group" "redis-subnet-group" {
  name       = "${var.env_name}-elasticache-subnet-group"
  subnet_ids = ["${var.subnet_a_id}", "${var.subnet_b_id}"]
}

resource "aws_elasticache_cluster" "redis-db" {
  cluster_id           = "microservices-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro" # Free tier eligible
  num_cache_nodes      = 1
  parameter_group_name = "default.redis6.2"
  engine_version       = "6.2"
  port                 = 6379

  # Free tier compatible settings
  snapshot_retention_limit = 1 # Keep only 1 snapshot
  maintenance_window       = "sun:04:00-sun:05:00"

  subnet_group_name  = aws_elasticache_subnet_group.redis-subnet-group.name
  security_group_ids = [aws_security_group.db-security-group.id]
}

# Setup a Route53 DNS entry for RDS routing
data "aws_route53_zone" "private-zone" {
  zone_id      = var.route53_id
  private_zone = true
}

resource "aws_route53_record" "rds-instance" {
  zone_id = var.route53_id
  name    = "rds.${data.aws_route53_zone.private-zone.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_db_instance.mysql-db.address]
}
