provider "aws" {
  region = "ap-south-1" # Mumbai region
  profile = "default"
}

# 1️⃣ VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "jenkins-vpc"
  }
}

# 2️⃣ Subnet
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "jenkins-subnet"
  }
}

# 3️⃣ Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "jenkins-igw"
  }
}

# 4️⃣ Route Table
resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "jenkins-rt"
  }
}

# 5️⃣ Route Table Association
resource "aws_route_table_association" "main_rta" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_rt.id
}

# 6️⃣ Security Group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins access"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# 7️⃣ IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# 8️⃣ IAM Policy Attachment
resource "aws_iam_role_policy_attachment" "ec2_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# 9️⃣ Instance Profile
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-ec2-role"
  role = aws_iam_role.ec2_role.name
}

# 🔟 EC2 Instance with Jenkins
resource "aws_instance" "jenkins_ec2" {
  ami                    = "ami-0861f4e788f5069dd" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main_subnet.id
  security_groups        = [aws_security_group.jenkins_sg.id]
  key_name               = "linux_ssh_keypair" # Make sure this key exists in your AWS account
  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install java-17-amazon-corretto -y

              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

              sudo yum install jenkins -y
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              EOF
  tags = {
    Name = "Jenkins-Server"
  }
}