# Configure the AWS Provider
provider "aws" {
  region  = "us-east-2"
}

data "aws_ami" "kali" {
  most_recent      = true
  owners           = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["*Kali Linux*"]
  }

}

resource "aws_security_group" "c2_group" {
  name        = "c2_group"
  description = "Allow Ports for C2 Listeners and SSH access"

# Open common web ports for C2
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

# Some more 1337 ports for c2 for fun
  ingress {
    from_port   = 1337
    to_port     = 1339
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

# c2 to ports that are over 9000, also for fun
  ingress {
    from_port   = 9001
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

# wide range of abitrary ports including some non standard web ports for c2
  ingress {
    from_port   = 8080
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks  = ["0.0.0.0/0"]
  }

# ssh for remote access, might want to lock down to your IP prior to rolling out
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks  = ["YOUR_IP"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "primary_c2" {
  ami           = "${data.aws_ami.kali.id}"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.c2_group.name}"]
  key_name = "primary-c2-key"

  provisioner "remote-exec" {
    script = "c2_setup.sh"
      connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = "${file("~/.ssh/primary-c2-key.pem")}"
        host     = "${self.public_ip}"
    }
  }

  tags = {
    Name = "Primary C2"
  }
}

output "IP" {
    value = "${aws_instance.primary_c2.public_ip}"
}
