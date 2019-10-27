# Configure the AWS Provider
provider "aws" {
  region  = "us-east-2"
}

data "aws_ami" "ubuntu" {
  most_recent      = true
  owners           = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

}

resource "aws_security_group" "kraken_ssh" {
  name        = "kraken_ssh_group"
  description = "Allow Port Kraken SSH access"

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

resource "aws_instance" "kraken" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "p2.8xlarge"
  security_groups = ["${aws_security_group.kraken_ssh.name}"]
  key_name = "primary-kraken-key"
  user_data = "${file("./kraken_setup.sh")}"
  
  tags = {
    Name = "Kraken"
  }
}

resource "aws_ebs_volume" "wordlists" {
  availability_zone = "us-east-2a"
  size              = 500

  tags = {
    Name = "Kraken Wordlists"
  }
}

resource "aws_volume_attachment" "wordlists_volume" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.wordlists.id}"
  instance_id = "${aws_instance.kraken.id}"
}

output "IP" {
    value = "${aws_instance.kraken.public_ip}"
}
