# aws-wordpress-cloudformation

## Project Overview

Design, deploy, and document a highly available AWS infrastructure using AWS CloudFormation and Infrastructure as Code (IaC) principles.

## Infrastructure Overview

The deployed AWS infrastructure includes:

- Custom Virtual Private Cloud (VPC)
- 2 Public Subnets across multiple Availability Zones
- 2 Private Subnets across multiple Availability Zones
- Internet Gateway (IGW)
- Public and Private Route Tables
- Route Table Associations
- Web Server Security Group (HTTP, HTTPS, SSH)
- Database Security Group (MySQL access from Web Server only)
- Amazon EC2 instance hosting WordPress
- Automated server configuration using CloudFormation UserData
- Apache Web Server installation and configuration
- PHP installation and configuration
- Automatic WordPress download and deployment
- Infrastructure deployment through AWS CloudFormation templates
- Reproducible Infrastructure as Code (IaC) implementation

## Key Deliverables
Infrastructure Components
- Network: VPC with 2 Public + 2 Private Subnets, Internet Gateway, Route Tables
- Security: Security Groups with appropriate inbound/outbound rules
- Compute: Auto Scaling Group with WordPress EC2 instances
- Database: Multi-AZ RDS MySQL

### Key Features

- Fully automated infrastructure deployment
- Infrastructure as Code (IaC) approach
- Multi-AZ network design
- Secure network segmentation using Security Groups
- Automated WordPress server provisioning
- Cost-effective deployment within AWS Sandbox environment

### Documentation

- CloudFormation Templates (YAML)
- Architecture Diagram
- README.md with complete deployment guide
- Screenshots of all resources
- Validation evidence
- Cleanup instructions
- Project summary

## Repository Structure

    aws-wordpress-cloudformation/
    │
    ├── templates/
    │   ├── network.yaml
    │   ├── security-groups.yaml
    │   ├── network-security.yaml
    │   └── wordpress-server.yaml
    │
    ├── parameters/
    │   ├── network-parameters.json
    │   ├── security-group-parameters.json
    │   └── wordpress-server-parameters.json
    │
    ├── scripts/
    │   ├── deploy.ps1
    │   └── deploywordpress.ps1
    │
    ├── screenshots/
    │   ├── Cloudformation-Stack.png
    │   ├── vpc.png
    │   ├── VPC with subnets.png
    │   ├── Security-Groups.png
    │   ├── EC2-Instance.png
    │   ├── Internet-Gateway.png
    │   ├── Security-ssh-access.png
    │   ├── Subnet-Associations.png
    │   ├── Route-Tables.png
    │   └── Subnets.png
    │
    ├── docs/
    │   ├── architecture-diagram.png
    │   └── deployment-guide.md
    │
    └── README.md

## Prerequisites:
- Account with appropriate permissions
- AWS CLI installed and configured
- VS Code with AWS Toolkit extension (optional)
- IAM User with CloudFormation full access

## Quick Start Guide

### 1. AWS account and access credentials
    # Check if AWS CLI is installed
    aws --version
    # Configure AWS CLI (if not already done)
    aws configure

### 2. Creating cloudFormation templates
    - vpc.yaml
    - security-groups.yaml
    - wordpress-server.yaml

### 3. Deployment with AWS CLI
    - Deploy VPC stack: automatically creates the AWS resources defined therein (VPC, subnets, etc.).
        aws cloudformation create-stack `
        --stack-name wordpress-vpc `
        --template-body file://templates/vpc.yaml `
        --parameters file://templates/vpc-parameters.
        
        aws cloudformation wait stack-create-complete --stack-name wordpress-vpc

        aws cloudformation describe-stacks --stack-name wordpress-vpc --query "Stacks[0].StackStatus"

### 4. Deploy the VPC stack
    # Retrieve VPC ID
    $VPC_ID = aws cloudformation describe-stacks `
    --stack-name wordpress-vpc `
    --query "Stacks[0].Outputs[?OutputKey=='VPC'].OutputValue" `
    --output text

    Write-Host "VPC ID: $VPC_ID" -ForegroundColor Green

    # Show all subnets
    aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone]" --output table
        -----------------------------------------------------------
        |                     DescribeSubnets                     |
        +---------------------------+---------------+-------------+
        |  subnet-04da942dfd0eae947 |  10.0.1.0/24  |  us-west-2a |
        |  subnet-09e0ba596ed69befa |  10.0.4.0/24  |  us-west-2b |
        |  subnet-0300f2c293b238c4d |  10.0.2.0/24  |  us-west-2b |
        |  subnet-0b84d687992d9d68a |  10.0.3.0/24  |  us-west-2a |
        +---------------------------+---------------+-------------+
    
    # Check Internet Gateway
    aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[*].[InternetGatewayId]" --output table
        ---------------------------
        |DescribeInternetGateways |
        +-------------------------+
        |  igw-0e3dadf16d03f8439  |
        +-------------------------+

    # Check route tables
    aws ec2 describe-route-tables `
    --filters "Name=vpc-id,Values=$VPC_ID" `
    --query "RouteTables[*].[RouteTableId, Associations[0].SubnetId]" `
    --output table                                                                        
        |                 DescribeRouteTables                 |
        +------------------------+----------------------------+
        |  rtb-058bad8d9f15faed9 |  None                      |
        |  rtb-0e6477d52f0f3d1b2 |  subnet-0300f2c293b238c4d  |
        |  rtb-07112b8f45060bd61 |  subnet-09e0ba596ed69befa  |
        |  rtb-028240e43ce99b2b5 |  subnet-0b84d687992d9d68a  |
        +------------------------+----------------------------+

    # Retrieve the VPC ID from the network stack
    $VPC_ID = aws cloudformation describe-stacks `
    --stack-name wordpress-vpc `
    --query "Stacks[0].Outputs[?OutputKey=='VPC'].OutputValue" `
    --output text

    Write-Host "VPC ID: $VPC_ID" -ForegroundColor Green

### 5. Deploy Security Groups Stack
    # Deploy Security Groups Stack with VPC ID
    aws cloudformation create-stack `
    --stack-name wordpress-security-groups `
    --template-body file://templates/security-groups.yaml `
    --parameters ParameterKey=EnvironmentName,ParameterValue=wordpress ParameterKey=VPC,ParameterValue=$VPC_ID `
    --capabilities CAPABILITY_NAMED_IAM

    # Wait until the stack is created
    aws cloudformation wait stack-create-complete --stack-name wordpress-security-groups

    # Check status
    aws cloudformation describe-stacks --stack-name wordpress-security-groups --query "Stacks[0].StackStatus"

### 6. Verify security groups
    # List all security groups in the VPC
    aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[*].[GroupName,GroupId,Description]" --output table

    # Show details of a specific security group
    aws ec2 describe-security-groups --group-ids $(aws cloudformation describe-stacks --stack-name wordpress-security-groups --query "Stacks[0].Outputs[?OutputKey=='EC2SecurityGroup'].OutputValue" --output text) --query "SecurityGroups[0].[IpPermissions, IpPermissionsEgress]" --output json
    [
        [
            {
                "IpProtocol": "-1",
                "UserIdGroupPairs": [
                    {
                        "UserId": "547224996589",
                        "GroupId": "sg-0f555552cddc87ad8"
                    }
                ],
                "IpRanges": [],
                "Ipv6Ranges": [],                                                                                                      
                "PrefixListIds": []                                                                                                    
            }                                                                                                                          
        ],                                                                                                                             
        [                                                                                                                              
            {                                                                                                                          
                "IpProtocol": "-1",                                                                                                    
                "UserIdGroupPairs": [],
                "IpRanges": [                                                                                                          
                    {                                                                                                                  
                        "CidrIp": "0.0.0.0/0"                                                                                          
                    }                                                                                                                  
                ],                                                                                                                     
                "Ipv6Ranges": [],                                                                                                      
                "PrefixListIds": []                                                                                                    
            }                                                                                                                          
        ]                                                                                                                              
    ]                                                                                                

#### Deploy with deploy.ps1
    # Output: 
        Deploying Network Stack...
        Waiting for changeset to be created..
        Waiting for stack create/update to complete
        Successfully created/updated stack - wordpress-network
        Network Stack Finished.
        Deploying Security Group Stack...
        Waiting for changeset to be created..
        Waiting for stack create/update to complete
        Successfully created/updated stack - wordpress-security
        Security Group Stack Finished.

### 7. Validation Evidence
    - scrennshots\VPC with subnets.png
    - scrennshots\Subnets.png
    - scrennshots\Subne-Associations.png
    - scrennshots\Route-Tables.png
    - scrennshots\Internet-Gateway.png
    - scrennshots\Security-Group.png

### 8. Cleanup Instructions (Powershell)
    # 1. Delete WordPress stack
    aws cloudformation delete-stack --stack-name wordpress-app
    aws cloudformation wait stack-delete-complete --stack-name wordpress-app

    # 2. Delete Security Groups stack
    aws cloudformation delete-stack --stack-name wordpress-security-groups
    aws cloudformation wait stack-delete-complete --stack-name wordpress-security-groups

    # 3. Delete VPC stack
    aws cloudformation delete-stack --stack-name wordpress-vpc
    aws cloudformation wait stack-delete-complete --stack-name wordpress-vpc

### 9. Create an Amazon EC2 Instance


    