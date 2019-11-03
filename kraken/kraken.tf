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

# Retrieve the AZ where we want to create network resources
# This must be in the region selected on the AWS provider.
data "aws_availability_zone" "kraken_zone" {
  name = "us-east-2a"
}

resource "aws_security_group" "kraken_ssh" {
  name        = "kraken_ssh_group"
  description = "Allow Port Kraken SSH access"

# ssh for remote access, might want to lock down to your IP prior to rolling out
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks  = ["75.62.72.13/32"]
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
  availability_zone = "${data.aws_availability_zone.kraken_zone.name}"

# Run this script as root once provisioning is complete. Ubuntu won't fetch our dependencies correctly if we run a remote-exec so this can't be fully automated for now.
 provisioner "file" {
    source      = "kraken_setup.sh"
    destination = "/tmp/kraken_setup.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/primary-kraken-key.pem")}"
      host        = "${self.public_ip}"
    }
  }

  tags = {
    Name = "Kraken"
  }
}

resource "aws_ebs_volume" "wordlists" {
  availability_zone = "${data.aws_availability_zone.kraken_zone.name}"
  size              = 500

  tags = {
    Name = "Kraken Wordlists"
  }
}

resource "aws_volume_attachment" "wordlists_volume" {
  device_name = "/dev/xvdh"
  volume_id   = "${aws_ebs_volume.wordlists.id}"
  instance_id = "${aws_instance.kraken.id}"
}

resource "null_resource" "data_config" {
  depends_on = ["aws_volume_attachment.wordlists_volume", "aws_instance.kraken"]
  
  ## run unmount commands when destroying the data volume
  provisioner "remote-exec" {
    when = "destroy"
    on_failure = "continue"
    connection {
      type = "ssh"
      agent = false
      timeout = "60s"
      user = "ubuntu"
      private_key = "${file("~/.ssh/primary-kraken-key.pem")}"
      host = "${aws_instance.kraken.public_ip}"
    }
    inline = ["sudo umount /media/wordlists"]
  }
}


output "IP" {
    value = "${aws_instance.kraken.public_ip}"
}
