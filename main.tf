provider "aws" {
  region = "eu-north-1"
  access_key = "YourAccessKey"
  secret_key = "SecretKey"

}

resource "aws_vpc" "example_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "example_igw" {
  vpc_id = aws_vpc.example_vpc.id
}

resource "aws_subnet" "example_subnet_public" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1c"
}

resource "aws_subnet" "example_subnet_private" {
  vpc_id            = aws_vpc.example_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1c"
}

resource "aws_security_group" "example_sg" {
  name        = "example_sg"
  description = "Example Security Group"

  vpc_id = aws_vpc.example_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "prom_server" {
  ami           = "ami-0a79730daaf45078a"
  instance_type = "t3.micro"
  key_name      = "Labb2"
  subnet_id     = aws_subnet.example_subnet_public.id
  vpc_security_group_ids = [aws_security_group.example_sg.id]

  user_data = <<-EOT
              # Налаштування Prometheus
              sudo apt-get update
              sudo apt-get install -y prometheus
              sudo systemctl enable prometheus
              sudo systemctl start prometheus

              # Налаштування Node-exporter
              sudo apt-get install -y prometheus-node-exporter
              sudo systemctl enable prometheus-node-exporter
              sudo systemctl start prometheus-node-exporter

              # Налаштування Cadvizor-exporter
              sudo apt-get install -y prometheus-cadvisor-exporter
              sudo systemctl enable prometheus-cadvisor-exporter
              sudo systemctl start prometheus-cadvisor-exporter
              EOF
}

resource "aws_instance" "cadvisor-node-exporter" {
  ami           = "ami-0a79730daaf45078a"
  instance_type = "t3.micro"
  key_name      = "Labb2"
  subnet_id     = aws_subnet.example_subnet_private.id
  vpc_security_group_ids = [aws_security_group.example_sg.id]

  user_data = <<-EOT
              sudo apt-get update
              sudo apt-get install -y prometheus-node-exporter
              sudo systemctl enable prometheus-node-exporter
              sudo systemctl start prometheus-node-exporter

              sudo apt-get install -y prometheus-cadvisor-exporter
              sudo systemctl enable prometheus-cadvisor-exporter
              sudo systemctl start prometheus-cadvisor-exporter
              EOT
}