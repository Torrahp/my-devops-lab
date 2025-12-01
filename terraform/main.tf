provider "aws" {
  region = "ap-southeast-1"
}

# 1. สร้าง Firewall (Security Group) เพื่อเปิดประตู
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web traffic"

  # เปิดประตูเข้า (Ingress) ที่ Port 80 (HTTP ปกติ)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # ยอมรับจากทุกที่ทั่วโลก
  }

  # เปิดประตูเข้า SSH (เผื่อไว้ debug)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # อนุญาตให้ออกไปข้างนอกได้หมด (Egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. ค้นหา Ubuntu Version ล่าสุด
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

# 3. สร้าง Server พร้อมสคริปต์ติดตั้ง
resource "aws_instance" "my_first_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.allow_web.id] # ผูกกับ Firewall ที่สร้างข้างบน

  # สคริปต์นี้จะรันเองอัตโนมัติ "แค่ครั้งแรก" ที่เปิดเครื่อง
  user_data = <<-EOF
              #!/bin/bash
              # 1. รอให้ระบบ Ubuntu อัปเดตตัวเองเสร็จก่อน (ป้องกัน error: apt locked)
              echo "Waiting for apt locks to be released..."
              while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
                echo "Waiting for other software managers..."
                sleep 5
              done
              while sudo fuser /var/lib/apt/lists/lock >/dev/null 2>&1; do
                echo "Waiting for other software managers..."
                sleep 5
              done

              # 2. เริ่มติดตั้ง Docker (คราวนี้จะไม่ชนกันแล้ว)
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker

              # 3. ให้สิทธิ์ Docker (เผื่อไว้)
              sudo usermod -aG docker ubuntu
              
              # ดึง Image จาก Docker Hub ของคุณ (แก้ชื่อ user ตรงนี้ถ้าไม่ใช่ tomwithjerry)
              sudo docker pull tomwithjerry/my-first-devops-project:latest
              
              # รัน App (map port 80 ของเครื่อง เข้า port 3000 ของ container)
              sudo docker run -d -p 80:3000 tomwithjerry/my-first-devops-project:latest
              EOF

  tags = {
    Name = "My-Full-DevOps-Server"
  }
}

# 4. บอกให้ Terraform ปริ้นท์ IP Address ออกมาให้เราดูตอนเสร็จ
output "server_public_ip" {
  value = aws_instance.my_first_server.public_ip
}