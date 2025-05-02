terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "david-bucket-aws-ten10"
    key = "terrraform.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "tvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name       = "david_terraform_vpc"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_vpc_endpoint" "ecr-dkr-endpoint" {
  vpc_id              = aws_vpc.tvpc.id
  service_name        = "com.amazonaws.eu-west-2.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.tsecgroup.id]
  subnet_ids          = [aws_subnet.tprivs.id]

  tags = {
    Name = "tdavid-ecr-dkr"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_vpc_endpoint" "ecr-api-endpoint" {
  vpc_id              = aws_vpc.tvpc.id
  service_name        = "com.amazonaws.eu-west-2.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  
  security_group_ids  = [aws_security_group.tsecgroup.id]
  subnet_ids          = [aws_subnet.tprivs.id]

  tags = {
    Name = "tdavid-ecr-api"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.tvpc.id
  service_name      = "com.amazonaws.eu-west-2.s3"
  route_table_ids   = [aws_route_table.trtpriv.id]
  
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "tdavid-ecr-s3"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_route_table_association" {
  route_table_id  = aws_route_table.trtpriv.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_internet_gateway" "tgw" {
  vpc_id = aws_vpc.tvpc.id

  tags = {
    Name       = "david_terraform_gateway"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_subnet" "tpubs" {
  vpc_id            = aws_vpc.tvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name       = "david_tpubs"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_subnet" "tpubs2" {
  vpc_id            = aws_vpc.tvpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name       = "david_tpubs"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_subnet" "tprivs" {
  vpc_id            = aws_vpc.tvpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name       = "david_tprivs"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_route_table" "trtpub" {
  vpc_id = aws_vpc.tvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tgw.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name       = "david_tpubroute"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_route_table" "trtpriv" {
  vpc_id = aws_vpc.tvpc.id

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }

  tags = {
    Name       = "david_tprivroute"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_main_route_table_association" "main_route_table" {
  vpc_id         = aws_vpc.tvpc.id
  route_table_id = aws_route_table.trtpriv.id
}

resource "aws_route_table_association" "trtpriv-as" {
  subnet_id      = aws_subnet.tprivs.id
  route_table_id = aws_route_table.trtpriv.id
}

resource "aws_route_table_association" "trtpubl-as" {
  subnet_id      = aws_subnet.tpubs.id
  route_table_id = aws_route_table.trtpub.id
}

resource "aws_route_table_association" "trtpubl2-as" {
  subnet_id      = aws_subnet.tpubs2.id
  route_table_id = aws_route_table.trtpub.id
}

resource "aws_security_group" "tsecgroup" {
  name        = "david_terraform_secgroup"
  description = "Allow HTTP, HTTPS and SSH traffic from local/subnet"
  vpc_id      = aws_vpc.tvpc.id

  tags = {
    Name       = "david_terraform_secgroup"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_security_group_rule" "ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["149.107.114.170/32"]
  security_group_id = aws_security_group.tsecgroup.id
}

resource "aws_security_group_rule" "ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tsecgroup.id
}

resource "aws_security_group_rule" "ingress_http_subnet" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.tsecgroup.id
}

resource "aws_security_group_rule" "ingress_http_port3000" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  source_security_group_id = aws_security_group.tsecgroup.id
  security_group_id = aws_security_group.tsecgroup.id
}

resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["149.107.114.170/32"]
  security_group_id = aws_security_group.tsecgroup.id
}

resource "aws_security_group_rule" "ingress_ssh_subnet" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"]
  security_group_id = aws_security_group.tsecgroup.id
}

resource "aws_security_group_rule" "egress_local" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.tsecgroup.id
}

resource "aws_lb_target_group" "tlb_targroup" {
  name        = "tdavid-lb-tgroup"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.tvpc.id

  tags = {
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_lb" "tloadbalancer" {
  name               = "david-terraform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tsecgroup.id]
  subnets            = [aws_subnet.tpubs.id, aws_subnet.tpubs2.id]

  tags = {
    Name       = "david-terraform-lb"
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_lb_listener" "tlb_listener" {
  load_balancer_arn = aws_lb.tloadbalancer.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tlb_targroup.arn
  }
}

resource "aws_ecs_cluster" "tcluster" {
  name = "tdavid-cluster"
  tags = {
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_ecs_task_definition" "task_def" {
  family                   = "tdavid-task-def"
  network_mode             = "awsvpc"
  execution_role_arn       = "arn:aws:iam::654463037626:role/ecsTaskExecutionRole"
  task_role_arn            = "arn:aws:iam::654463037626:role/ECS-Console-V2-TaskDefinition-ECSTaskExecutionRole-1230Y43405CX5"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions = jsonencode([
    {
      name      = "private-instance"
      image     = "654463037626.dkr.ecr.eu-west-2.amazonaws.com/david-repo:latest",
      essential = true,
      cpu       = 0,
      portMappings = [
        {
          name          = "private-instance-80-tcp"
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      networkMode : "awsvpc",
      cpu    = 1,
      memory = 500,
      runtimePlatform = {
        "cpuArchitecture" : "X86_64",
        "operatingSystemFamily" : "LINUX"
      }
    }
  ])
  tags = {
    Department = "Training = Platform Engineering 1"
  }
}

resource "aws_ecs_service" "tservice" {
  name            = "tdavid-service"
  cluster         = aws_ecs_cluster.tcluster.id
  task_definition = aws_ecs_task_definition.task_def.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = [aws_subnet.tprivs.id]
    security_groups  = [aws_security_group.tsecgroup.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tlb_targroup.arn
    container_name   = "private-instance"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_lb_listener.tlb_listener]

  tags = {
    Department = "Training = Platform Engineering 1"
  }
}