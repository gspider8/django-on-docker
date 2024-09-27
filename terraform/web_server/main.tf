# -- web_server.compute --
data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"] # ignore date
  }
}

data "aws_key_pair" "main" {
  key_name = var.aws_key_name
  include_public_key = true
}

data "aws_eip" "main" {
  public_ip = var.eip_public_ip
}

resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.main.id]
  tags = {
    Name    = "${var.project_name}_final"
    Project = var.project_name
  }
  root_block_device {
    volume_size = 50
  }
#   user_data
}

resource "aws_eip_association" "my_eip_association" {
  instance_id   = aws_instance.main.id
  allocation_id = data.aws_eip.main.id
}
