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
          "tag:Name": var.vpc_tagName
      }
  }

  subnet_filter {
    random = true
    filters = {
        "tag:Environment": var.subnet_tagEnvironment,
        "tag:Name": var.subnet_tagName
    }
  }  

  security_group_filter {
      filters = {
          "vpc-id": var.sg_tagVPC
          "group-id": var.sg_tagGroup
      }
  }

    tags = {
        Name              = local.ami_name
        BuiltBy           = "Packer"
        App               = var.name
        AppVersion        = var.app_version
        Environment       = var.env
        SourceAMI         = "{{ .SourceAMIName }}"
        ManagedBy         = var.managedby
        JenkinsBuildID    = var.jenkins_build_id
    }


}



build {
  sources = ["source.amazon-ebs.main"]
  
  provisioner "file" {
    source      = "files/bootstrap.json"
    destination = "/tmp/config.json"
  }
  
  provisioner "shell" {
    inline = [
        "sleep 3",
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
        "sudo mkdir -p /etc/consul.d/{bootstrap,server,client}",
        "sudo mkdir /var/consul",
        "sudo mv /tmp/config.json /etc/consul.d/bootstrap/config.json",
        "sudo chown -R consul:consul /var/consul"
    ]
  }

}
