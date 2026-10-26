data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

###############################################################################
# Bastion IAM Role (SSM Session Manager + kubeconfig 생성용 eks:DescribeCluster)
###############################################################################
resource "aws_iam_role" "bastion" {
  name = "${var.name}-role-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "eks" {
  name = "eks-describe"
  role = aws_iam_role.bastion.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Resource = "*"
    }]
  })
}

###############################################################################
# Bastion Access Entry (클러스터 kubectl 권한)
###############################################################################
resource "aws_eks_access_entry" "bastion" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.bastion.arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "bastion" {
  cluster_name  = var.cluster_name
  principal_arn = aws_eks_access_entry.bastion.principal_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/${var.access_policy_name}"

  access_scope {
    type = "cluster"
  }
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.name}-ip-bastion"
  role = aws_iam_role.bastion.name

  tags = var.tags
}

###############################################################################
# Bastion Security Group (기본 inbound 없음, ssh_allowed_cidrs 지정 시 22 허용)
###############################################################################
resource "aws_security_group" "bastion" {
  name        = "${var.name}-sg-bastion"
  description = "Bastion host"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.name}-sg-bastion"
  })
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.ssh_allowed_cidrs)

  security_group_id = aws_security_group.bastion.id
  description       = "SSH from ${each.value}"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.bastion.id
  description       = "All outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

###############################################################################
# Bastion Instance
###############################################################################
resource "aws_instance" "bastion" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data_replace_on_change = true
  user_data                   = <<-EOF
    #!/bin/bash
    set -euo pipefail
    KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable-${var.cluster_version}.txt)
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    chmod +x /usr/local/bin/kubectl
    su - ec2-user -c "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${var.cluster_name}"
    # ssm-user 는 첫 Session Manager 접속 시 생성되며 /etc/skel 을 복사함
    mkdir -p /etc/skel/.kube
    cp /home/ec2-user/.kube/config /etc/skel/.kube/config
  EOF

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.tags, {
    Name = "${var.name}-bastion"
  })

  # AMI 최신화로 인한 의도치 않은 재생성 방지
  lifecycle {
    ignore_changes = [ami]
  }

  depends_on = [aws_iam_role_policy_attachment.ssm]
}
