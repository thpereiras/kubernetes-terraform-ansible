variable "access_key" {
  description = "Value from secret.tfvar"
}

variable "secret_key" {
  description = "Value from secret.tfvar"
}

variable "ami" {
  default = "ami-0f84c9a9348f9f857"
}

variable "image_flavor" {
  type = map
  default = {
    master = "t2.medium"
    worker = "t2.medium"
  }
}

variable "aws_region" {
  default = "us-east-1"
}

variable "tag_name" {
  default = "k8s-cluster"
}

variable "master_count" {
  default = "1"
}

variable "node_count" {
  default = "2"
}

variable "aws_key_pair_name" {
  description = "Key pair name created in ec2 Key Pairs session"
  default     = "k8s-key"
}

variable "vpc_cidr" {
  default = "10.10.0.0/16"
}

variable "subnet_cidr" {
  default = "10.10.10.0/24"
}

variable "publicDestCIDRblock" {
    default = "0.0.0.0/0"
}

variable "subnet_availability_zone" {
  default = "us-east-1a"
}

variable "sg_ingress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
    default     = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks  = ["0.0.0.0/0"]
          description = "test"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks  = ["0.0.0.0/0"]
          description = "HTTP port"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks  = ["0.0.0.0/0"]
          description = "HTTPS port"
        },
        # {
        #   from_port   = 6443
        #   to_port     = 6443
        #   protocol    = "tcp"
        #   cidr_blocks  = ["10.10.0.0/16"]
        #   description = "Kubernetes API Server port"
        # },
        # {
        #   from_port   = 179
        #   to_port     = 179
        #   protocol    = "tcp"
        #   cidr_blocks  = ["10.10.0.0/16"]
        #   description = "Kubernetes - Calico networking (BGP)"
        # },
        # {
        #   from_port   = 0
        #   to_port     = 65535
        #   protocol    = "tcp"
        #   cidr_blocks  = ["10.10.0.0/16"]
        #   description = "Kubernetes - Intracluster communication"
        # },
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks  = ["10.10.0.0/16"]
          description = "Kubernetes API Server port"
        }
    ]
}

variable "sg_egress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
    default     = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks  = ["0.0.0.0/0"]
          description = "Allow all egress traffic"
        }
    ]
}
