provider "aws" {
  region = "eu-west-3"
}

data "aws_security_group" "default" {
  name   = "default"
  vpc_id = module.vpc.vpc_id
}

data "aws_availability_zones" "az" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "devops"

  cidr = "10.0.0.0/16"

  azs             = "${data.aws_availability_zones.az.names}"
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_ipv6 = false

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Name = "public-subnet"
  }

  tags = {
    Owner = "DevOps"
    Environment = "poc"
  }

  vpc_tags = {
    Name = "DevOps VPC"
  }
}

resource "aws_security_group" "allow-ssh" {
name = "allow-ssh"
vpc_id = "${module.vpc.vpc_id}"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 22
    to_port = 22
    protocol = "tcp"
  }
// Terraform removes the default rule
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_security_group" "allow_http" {
name = "allow_http"
vpc_id = "${module.vpc.vpc_id}"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 80
    to_port = 80
    protocol = "tcp"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-bionic*"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  filter {
    name = "architecture"
    values = [
      "x86_64"]
  }

  owners = [
    "099720109477"]
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDML39sGJP4vIhNKkyTL3eD87UfPHDrLi6pFLO/E/5vXka3oyjuuIZ0rVXlRBZWWIUYDQoiAlGt+lk8rFd0a6WtaHvXHrG5ejI9oW968R+25ZOYQ1dy3LQWvAI+H0i1LK+ohSbwdtEz5kSN0JJMfRd3QPyNB/fCNpKq0pEuDsztlMC255ntuQiZaaATtZA8AIXJXORemhlf3dN3GbHYHaWchskJpBZaH10vO2Cua4zEhm1XlbejmJvMNLAb+Cafr5Ay+1HM2J7qS52oa0SYtxUGAR7dFyCBOoFdR3YVfJKGv3f0V7S9DgF6ougVn+I2xTAIaFUE87V4EnnwIrPiVpcN3oK0tF4QdY2NsEBW+2IlJmMaI1Krlr0i4PeEE/PnDVy52lkr4CuvaHTOHoiiW/FE/QNhq8JsbwZy25sWo1cn5GT7k1JuM6cv0tX6Pk+r0bKiRPi5ATH4WEXF10fWt9tMtdbB49dpMqF1m87aBGkQ452i4c9gskIOVdTKevu1tzNDoD/bKTiGFajoeMCN1xE5iDoWFTVY5g1hel9b1P1TMrD25M8z9ishyjWb+B3R9BsS/Y4AKSRrFGxEYLZTNU9IO6tkxWm9jHhQmkt9N2xL3wIJN3UL1SwPGdXRObeWMmBqLS8xnhTUH1BLqW9zREAVQRs6t/Be1BZLVS31MFWQkw== mike@mike-Precision-7530"
}

resource "aws_instance" "jenkins" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t3.medium"
  key_name = "${aws_key_pair.ssh_key.key_name}"
  security_groups = []
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}", "${aws_security_group.allow_http.id}"]
  subnet_id = "${module.vpc.public_subnets[0]}"

  tags = {
    Name = "Jenkins"
    Owner = "DevOps"
    Environment = "poc"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
  }

  # workaround for cloud-init
  provisioner "remote-exec" {
    inline = ["while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"]
  }

  provisioner "salt-masterless" {
    local_state_tree = "./srv/salt"
    local_pillar_roots = "./srv/pillars"
    bootstrap_args = "-P -x python3"
    log_level = "info"
    minion_config_file = "./srv/jenkins.yaml"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = "${file("devops")}"
    timeout = "10m"
  }
}


resource "aws_instance" "nexus" {
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t3.medium"
  key_name = "${aws_key_pair.ssh_key.key_name}"
  security_groups = []
  associate_public_ip_address = true
  vpc_security_group_ids = ["${aws_security_group.allow-ssh.id}", "${aws_security_group.allow_http.id}"]
  subnet_id = "${module.vpc.public_subnets[0]}"

  tags = {
    Name = "Nexus"
    Owner = "DevOps"
    Environment = "poc"
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = "30"
  }

  # workaround for cloud-init
  provisioner "remote-exec" {
    inline = ["while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"]
  }

  provisioner "salt-masterless" {
    local_state_tree = "./srv/salt"
    local_pillar_roots = "./srv/pillars"
    bootstrap_args = "-P -x python3"
    log_level = "info"
    minion_config_file = "./srv/nexus.yaml"
  }

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ubuntu"
    private_key = "${file("devops")}"
    timeout = "10m"
  }
}