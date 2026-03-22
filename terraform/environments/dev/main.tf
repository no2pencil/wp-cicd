data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

module "vpc" {
  source = "../../modules/vpc"

  name            = "wp-dev"
  cidr_block      = "10.0.0.0/16"
  azs             = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.10.0/24", "10.0.11.0/24"]
}

# MySQL EC2
module "mysql" {
  source = "../../modules/ec2"

  name            = "mysql"
  instance_count  = 1
  ami             = data.aws_ssm_parameter.amazon_linux.value
  instance_type   = "t3.micro"
  subnet_ids      = module.vpc.private_subnet_ids
  vpc_id          = module.vpc.vpc_id

  ingress_rules = [
    {
      description     = "MySQL from web"
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [] # fill later with WP SG
    }
  ]
}

# WordPress EC2 (2 instances)
module "wordpress" {
  source = "../../modules/ec2"

  name            = "wordpress"
  instance_count  = 2
  ami             = data.aws_ssm_parameter.amazon_linux.value
  instance_type   = "t3.micro"
  subnet_ids      = module.vpc.public_subnet_ids
  vpc_id          = module.vpc.vpc_id
  key_name        = var.key_name
  associate_public_ip = true

  ingress_rules = [
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["${var.my_ip}/32"]
    }
  ]
}
