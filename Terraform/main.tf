#vpc
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "app-vpc-${var.ENV_PREFIX}"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
  manage_default_security_group = false
  manage_default_network_acl = false

  tags = {
    Terraform = "true"
    Environment = var.ENV_PREFIX
  }
}

//security groups
resource "aws_security_group" "web_sg" {
  name        = "app-${var.ENV_PREFIX}-sg"
  description = "allows http, https and ssh"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules → egress
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.ENV_PREFIX
  }
}

//instance
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "web-${var.ENV_PREFIX}-instance"

  ami = "ami-0360c520857e3138f"
  instance_type = "t3.micro"
  key_name      = "N.VIRGINIA-KEY"
  monitoring    = true
  subnet_id     = module.vpc.public_subnets[0]
  vpc_security_group_ids    = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  
  create_security_group = false

  tags = {
    Terraform   = "true"
    Environment = var.ENV_PREFIX
  }
}

resource "aws_eip" "web_eip" {
  instance = module.ec2_instance.id
  domain   = "vpc"

  tags = {
    Name = "${var.ENV_PREFIX}-eip"
  }
}


