# -- web_server.security_groups --
locals {
  security_groups = {
    main = {
      ip_ranges = {
        local_ssh = {
          description = "SSH Access"
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_block  = var.my_ip
        }
        local_8000 = {
          description = "App Server Access"
          from        = 8000
          to          = 8000
          protocol    = "tcp"
          cidr_block  = var.my_ip
        }
        local_http = {
          description = "local http"
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_block  = var.my_ip
        }
        local_https = {
          description = "local https"
          from        = 443
          to          = 443
          protocol    = "tcp"
          cidr_block  = var.my_ip
        }
        eip_http = {
          description = "self referential to allow eip http traffic"
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_block  = "${var.eip_public_ip}/32"
        }
        open_http = {
          description = "Open HTTP Access"
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        }
        open_https = {
          description = "OPEN HTTPS Access"
          from        = 443
          to          = 443
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
        }
      }
      referential_ingress = {
        self_referential = {
          description                  = "default"
          referenced_security_group_id = aws_security_group.main.id
          ip_protocol                  = -1
        }
      }
    }
  }
}

resource "aws_security_group" "main" {
  name = var.project_name
  tags = {
    Project = var.project_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  for_each          = local.security_groups.main.ip_ranges
  security_group_id = aws_security_group.main.id

  description = each.value.description
  cidr_ipv4   = each.value.cidr_block
  from_port   = each.value.from
  to_port     = each.value.to
  ip_protocol = each.value.protocol
}

resource "aws_vpc_security_group_ingress_rule" "self_referential" {
  security_group_id            = aws_security_group.main.id

  for_each                     = local.security_groups.main.referential_ingress # aws_security_group.main.id
  description                  = each.value.description
  referenced_security_group_id = each.value.referenced_security_group_id
  ip_protocol                  = each.value.ip_protocol
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}