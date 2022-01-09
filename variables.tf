variable base-ami {
  type = string
  default = "ami-07ef508d01f533f5f"
}

variable instance-type {
  type = string
  default = "t4g.medium"
}

variable ssh-key-pair-name {
  type = string
}
