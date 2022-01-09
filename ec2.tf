data http my-ip {
  url = "http://ipv4.icanhazip.com"
}

resource aws_security_group server-sg {
  name = "Minecraft Server"
  description = "Opens ports required for server access and administration"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description = "SSH access"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.my-ip.body)}/32"]
  }

  ingress {
    description = "Minecraft client access tcp"
    from_port = 25565
    to_port = 25565
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Minecraft client access udp"
    from_port = 25565
    to_port = 25565
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
