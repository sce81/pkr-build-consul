source "amazon-ebs" "main" {
  profile         = "raxaws"
  ami_name        = "${local.ami_name}-${var.jenkins_build_id}"
  ami_description = "${var.name}-${var.env}-${local.timestamp}"

  instance_type = var.instancetype
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "amzn2-ami-hvm-2.0.20210326.0-x86_64-gp2"
      root-device-type    = "ebs"
      architecture        = "x86_64"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["137112412989"]
  }
  ssh_username  = "ec2-user"
  ssh_interface = "private_ip"
  ebs_optimized = true



  vpc_filter {
      filters = {
          "tag:Name": "sandbox1-main-vpc"
      }
  }

  subnet_filter {
    random = true
    filters = {
        "tag:Environment": "sandbox1",
        "tag:Name": "sandbox1-core-*"
    }
  }  

  security_group_filter {
      filters = {
          "vpc-id": "vpc-046340e71f03ad85e"
          "group-id": "sg-07d5022d92074a96a",
      }
  }

    tags = {
        Name              = local.ami_name
        BuiltBy           = "Packer"
        App               = var.name
        AppVersion        = var.app_version
        Environment       = var.env
        SourceAMI         = "{{ .SourceAMIName }}"
        ManagedBy         = "Rackspace"
        JenkinsBuildID    = var.jenkins_build_id
    }


}



build {
    sources = ["source.amazon-ebs.main"]

  provisioner "shell" {
    inline = [
              "sleep 2",
              "sudo yum update -y"
    ]
  }
  provisioner "shell" {
    inline = [
              "sudo yum install -y yum-utils",
              "wget https://releases.hashicorp.com/consul/${var.app_version}/consul_${var.app_version}_linux_amd64.zip",
              "unzip consul_${var.app_version}_linux_amd64.zip",
              "sudo mv consul /usr/local/bin/",
              "mkdir -p ~/.aws/",
              "echo '[default]' > ~/.aws/config",
              "echo 'region = REGION' >> ~/.aws/config"
    ]
  }
  provisioner "shell" {
    inline = [
        "sudo adduser consul",
        "mkdir -p /etc/consul.d/{bootstrap,server,client}",
        "mkdir /var/consul",
        "sudo chown consul:consul /var/consul"
    ]
  }
  provisioner "file" {
    source      = "files/bootstrap.json"
    destination = "/etc/consul.d/bootstrap/config.json"
  }
}