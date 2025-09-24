resource "aws_vpc" "test_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true 

  tags = {
    Name = "test_vpc"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

//one public subnet, two public subnets
resource "aws_subnet" "test_public_subnet" {
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = cidrsubnet(aws_vpc.test_vpc.cidr_block,8,0)
  map_public_ip_on_launch = true 
  availability_zone       = data.aws_availability_zones.available.names[0] 

  tags = {
    Name = "test_public_subnet"
    "karpenter.sh/discovery" = "test_eks_cluster"
  }
}

resource "aws_subnet" "test_private_subnet" {
  count      = 2
  vpc_id     = aws_vpc.test_vpc.id
  cidr_block = cidrsubnet(aws_vpc.test_vpc.cidr_block, 8, 110 + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "test_private_subnet_${count.index + 1}"
    "karpenter.sh/discovery" = "test_eks_cluster" 
  }
}

//internet gateway for public subnet and nat gateway for private subnets
resource "aws_internet_gateway" "test_igw" {
  vpc_id = aws_vpc.test_vpc.id

  tags = {
    Name = "test_igw"
  }
}

resource "aws_eip" "test_eip" {
   domain = "vpc"
  depends_on                = [aws_internet_gateway.test_igw]
}

resource "aws_nat_gateway" "test_nat_gateway" {
  allocation_id = aws_eip.test_eip.id
  subnet_id     = aws_subnet.test_public_subnet.id

  tags = {
    Name = "test_nat_gateway"
  }

  depends_on = [aws_internet_gateway.test_igw]
}

//public and private route tables
resource "aws_route_table" "test_public_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test_igw.id
  }

  tags = {
    Name = "test_public_rt"
  }
}

resource "aws_route_table" "test_private_rt" {
  vpc_id = aws_vpc.test_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.test_nat_gateway.id
  }

  tags = {
    Name = "test_private_rt"
  }
}

//rt & subnets association
resource "aws_route_table_association" "test_public_subnet_association" {
  subnet_id      = aws_subnet.test_public_subnet.id
  route_table_id = aws_route_table.test_public_rt.id
}

resource "aws_route_table_association" "test_private_subnet_association" {
  count          = 2  
  subnet_id      = aws_subnet.test_private_subnet[count.index].id
  route_table_id = aws_route_table.test_private_rt.id
}