# Create vpc name "main"
resource "aws_vpc" "main" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

# Add subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev_public"
  }
}

# Add aws internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "dev_igw"
  }
}

# Add aws route table
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main.id

    tags = {
      "Name" = "dev_public_rta"
    }
  
}

# Add aws route
resource "aws_route" "default_route" {
    route_table_id = aws_route_table.public_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  
}

# Add aws route table association
resource "aws_route_table_association" "route_table_association" {
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id
  
}

# Add security group
resource "aws_security_group" "sg" {
    name = "dev_sg"
    description = "dev security group"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0" ]

    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [ "0.0.0.0/0"]

    }
  
}

# Create a key pair
resource "aws_key_pair" "authentication_key" {
    key_name = "dev_key"
    public_key = file("~/.ssh/mtckey.pub")
  
}

# Add aws ec2 instance
resource "aws_instance" "dev_node" {
    instance_type = "t2.micro"        
    ami = data.aws_ami.ubuntu_server.id
    user_data = file("userdata.tpl")
    key_name = aws_key_pair.authentication_key.id
    vpc_security_group_ids = [ aws_security_group.sg.id ]
    subnet_id = aws_subnet.public_subnet.id

    root_block_device {
      volume_size = 10
    }

    tags = {
      "Name" = "Dev_node"
    }
     
}