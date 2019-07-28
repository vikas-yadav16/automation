# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "terraform-example" {
  cidr_block       = "10.2.0.0/16"

  tags = {
    Name = "vikas-terra"
    email= "vikas.yadav@quantiphi.com"
  }
}

# CREATE INTERNET GATEWAY
resource "aws_internet_gateway" "vikas-gateway" {
    vpc_id = "${aws_vpc.terraform-example.id}"
    tags = {
    Name = "vikas-terra-ig"
    Email= "vikas.yadav@quantiphi.com"
  }
}

# CREATE PUBLIC SUBNET
resource "aws_subnet" "vikas-pubsubnet" {
  vpc_id     = "${aws_vpc.terraform-example.id}"
  cidr_block = "10.2.1.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "vikas-terra-public"
    Email= "vikas.yadav@quantiphi.com"
  }
}


# CREATE ROUTE TABLE
resource "aws_route_table" "vikas-terraform-publicroute" {
    vpc_id = "${aws_vpc.terraform-example.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.vikas-gateway.id}"
    }

    tags = {
        Name = "vikas-terraform-public"
        Email= "vikas.yadav@quantiphi.com"
    }
}


# ASSOCIATE ROUTE TABLE
resource "aws_route_table_association" "vikas-terraform-route-a" {
    subnet_id = "${aws_subnet.vikas-pubsubnet.id}"
    route_table_id = "${aws_route_table.vikas-terraform-publicroute.id}"
}

# CREATE 2 PRIVATE SUBNETS
resource "aws_subnet" "vikas-terraform-privatesubnet1" {
  vpc_id     = "${aws_vpc.terraform-example.id}"
  cidr_block = "10.2.2.0/24"
  availability_zone = "us-east-1d"
  tags = {
    Name = "vikas-private1-terraform"
    Email= "vikas.yadav@quantiphi.com"
  }
}
resource "aws_subnet" "vikas-terraform-privatesubnet2" {
  vpc_id     = "${aws_vpc.terraform-example.id}"
  cidr_block = "10.2.3.0/24"
  availability_zone = "us-east-1e"
  tags = {
    Name = "vikas-private2-terraform"
    Email= "vikas.yadav@quantiphi.com"
  }
}




# CREATE SECURITY GROUPS FOR PUBLIC INSTANCE

resource "aws_security_group" "vikas-tf-public1" {
    name = "vikas-tf-public1"
    description = "Allow incoming HTTP connections."
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.terraform-example.id}"

    tags = {
        Name = "vikas-tf-public1"
        Email= "vikas.yadav@quantiphi.com"
    }
}

# CREATE PUBLIC INSTANCE

resource "aws_instance" "vikas-public" {
    ami = "ami-026c8acd92718196b"
    availability_zone = "us-east-1d"
    instance_type = "t2.micro"
    key_name = "firstec2"
    vpc_security_group_ids = ["${aws_security_group.vikas-tf-public1.id}"]
    subnet_id = "${aws_subnet.vikas-pubsubnet.id}"
    associate_public_ip_address = true
    source_dest_check = false


    tags = {
        Name = "vikas-tf-public"
        Email= "vikas.yadav@quantiphi.com"
    }
}

# CREATE SECURITY GROUP FOR PRIVATE INSTANCE

resource "aws_security_group" "vikas-tf-private1" {
    name = "vikas-tf-private1"
    description = "Only ssh"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.terraform-example.id}"

    tags = {
        Name = "vikas-tf-private1"
        Email= "vikas.yadav@quantiphi.com"
    }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/startup.tpl")}"
  vars = {
    db_password = "${aws_db_instance.vikas-rds-terraform.password}"
    endpoint = "${aws_db_instance.vikas-rds-terraform.endpoint}"
  }
}



data "template_file" "user_data" {
  template = "${file("${path.module}/script.tpl")}"
  vars = {
    db_password = "${aws_db_instance.vikas-rds-terraform.password}"
    endpoint = "${aws_db_instance.vikas-rds-terraform.endpoint}"
  }
}

resource "aws_instance" "vikas-private1" {
    ami = "ami-026c8acd92718196b"
    availability_zone = "us-east-1d"
    instance_type = "t2.micro"
    key_name = "firstec2"
    vpc_security_group_ids = ["${aws_security_group.vikas-tf-private1.id}"]
    subnet_id = "${aws_subnet.vikas-terraform-privatesubnet1.id}"
    source_dest_check = false
    user_data = "${data.template_file.user_data.rendered}"


    tags = {
        Name = "vikas-tf-private1"
        Email= "vikas.yadav@quantiphi.com"
    }
}



resource "aws_route_table" "vikas-terraform-privatesubnet" {
    vpc_id = "${aws_vpc.terraform-example.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.vikas-nat.id}"
    }

    tags= {
        Name = "vikas-tf-private"
        Email= "vikas.yadav@quantiphi.com"
    }
}





resource "aws_route_table_association" "vikas-terraform-privatesubnet1" {
    subnet_id = "${aws_subnet.vikas-terraform-privatesubnet1.id}"
    route_table_id = "${aws_route_table.vikas-terraform-privatesubnet.id}"
}




resource "aws_db_instance" "vikas-rds-terraform" {
  allocated_storage    = 10
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "vikas"
  identifier           = "vikas-rds-terraform"
  password             = "vikas987"
  parameter_group_name = "default.mysql5.7"
  db_subnet_group_name = aws_db_subnet_group.vikas-rds-terraform.name
  vpc_security_group_ids = ["${aws_security_group.db-security.id}"]
  tags = {
    Name = "vikas-rds-terraform"
    Email= "vikas.yadav@quantiphi.com"
  }
}

resource "aws_db_subnet_group" "vikas-rds-terraform" {
  name       = "vikas-rds-terraform"
  subnet_ids = ["${aws_subnet.vikas-terraform-privatesubnet2.id}","${aws_subnet.vikas-terraform-privatesubnet1.id}"]
  tags = {
    Name = "vikas-rds-terraform"
    Email= "vikas.yadav@quantiphi.com"
  }
}

resource "aws_security_group" "db-security"{
  name = "db-security-group"
  vpc_id = "${aws_vpc.terraform-example.id}"
  ingress{
     from_port = 3306
     to_port = 3306
     protocol = "tcp"
     security_groups = ["${aws_security_group.vikas-tf-private1.id}"]
  }

  egress{
     from_port = 0
     to_port = 0
     protocol = "tcp"
     cidr_blocks = ["0.0.0.0/0"]

}
  tags= {
    Name = "vikas-db"
    Email = "vikas.yadav@quantiphi.com"
  }


}

# CREATE NAT GATEWAY 
resource "aws_nat_gateway" "vikas-nat"{
   allocation_id ="eipalloc-0a5525656c8abf5e0"
   subnet_id = "${aws_subnet.vikas-pubsubnet.id}"
   tags= {
    Name = "vikas-nat"
    Email = "vikas.yadav@quantiphi.com"
   }



}




