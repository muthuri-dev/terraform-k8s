
resource "aws_vpc" "dev_vpc" {
  cidr_block       = var.dev_vpc_cidr_block
  instance_tenancy = "default" # default , dedicated , host 

  tags = {
    Name = "dev_vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "dev_public_subnet" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.dev_vpc.cidr_block, 8, 10)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "dev_public_subnet"
  }
}

resource "aws_subnet" "dev_private_subnet" {
  count             = 3
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.dev_vpc.cidr_block, 8, count.index + 110)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "dev_private_subnet_${count.index + 1}"
  }
}

#internet gateway
resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

#natsgateway
resource "aws_eip" "dev_lb" {
  domain = "vpc"
}


resource "aws_nat_gateway" "dev_nat_gateway" {
  allocation_id = aws_eip.dev_lb.id
  subnet_id     = aws_subnet.dev_public_subnet.id

  tags = {
    Name = "dev_nat_gateway"
  }

  depends_on = [aws_internet_gateway.dev_igw, aws_eip.dev_lb]
}


#route table
resource "aws_route_table" "dev_public_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }


  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route_table" "dev_private_rt" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dev_nat_gateway.id
  }


  tags = {
    Name = "dev_private_rt"
  }
}

#association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.dev_public_subnet.id
  route_table_id = aws_route_table.dev_public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.dev_private_subnet[0].id
  route_table_id = aws_route_table.dev_private_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.dev_private_subnet[1].id
  route_table_id = aws_route_table.dev_private_rt.id
}

resource "aws_route_table_association" "d" {
  subnet_id      = aws_subnet.dev_private_subnet[2].id
  route_table_id = aws_route_table.dev_private_rt.id
}