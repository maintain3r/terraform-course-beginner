subnet_config = {
  subnet_1 = {
    cidr_block = "10.10.1.0/24"
    az = "us-east-1a"
  },
  subnet_2 = { 
    cidr_block = "10.10.2.0/24"
    az = "us-east-1b"
  },
  subnet_3 = { 
    cidr_block = "10.10.3.0/24"
    az = "us-east-1c"
  },
  subnet_10 = { 
    cidr_block = "10.10.10.0/24"
    az = "us-east-1a"
    public = true
  },
}
