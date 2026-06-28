# aws-wordpress-cloudformation

## Project Overview

This project demonstrates the deployment of a highly available WordPress environment on AWS using Infrastructure as Code (IaC) with AWS CloudFormation.

The implementation is divided into three phases:

### Phase 1
- VPC
- Public Subnets
- Private Subnets
- Internet Gateway
- Route Tables
- Security Groups

### Phase 2
- EC2 Deployment
- Apache Installation
- PHP Installation
- WordPress Deployment
- CloudFormation UserData Automation

### Phase 3
- Application Load Balancer (ALB)
- Launch Template
- Auto Scaling Group
- CloudWatch Alarms
- Dynamic Scaling Policies

## Architecture Diagram


## Prerequisites:

- Account with appropriate permissions
- AWS CLI installed and configured
- VS Code with AWS Toolkit extension (optional)

## Repository Structure

    aws-wordpress-cloudformation/
    │
    ├── templates/
    │   ├── network.yaml                     (Phase 1 - optional)
    │   ├── security-groups.yaml             (Phase 1 - optional)
    │   ├── network-security.yaml            ✅ Phase 1 - Haupttemplate
    │   ├── wordpress-server.yaml            ✅ Phase 2 - WordPress EC2
    │   ├── wordpress-ha.yaml                🆕 Phase 3 - ALB + Auto Scaling
    │   ├── network-parameters.json          (optional)
    │   ├── security-group-parameters.json   (optional)
    │   └── wordpress-server-parameters.json ✅ Parameter
    │
    ├── scripts/
    │   ├── deploy.ps1                       (Phase 1 - optional)
    │   ├── deploy-phase2.ps1                ✅ Phasen 1+2
    │   ├── deploy-phase3.ps1                🆕 Phase 3
    │   ├── deploy-all.ps1                   🆕 Alle Phasen
    │   └── cleanup-all.ps1                  🆕 Aufräumen
    │
    ├── screenshots/                         
    │   ├── phase1/
    │   │   ├── vpc.png
    │   │   ├── VPC with subnets.png
    │   │   ├── Security-Groups.png
    │   │   ├── Internet-Gateway.pngg
    │   │   ├── Subnet-Associations.png
    │   │   ├── Route-Tables.png
    │   │   └── Subnets.png
    │   ├── phase2/
    │   │   ├── Cloudformation-Stack.png
    │   │   ├── EC2-Instance.png
    │   │   ├── Security-ssh-access.png
    │   │   ├── Apache-Working.png
    │   │   ├── Wordpress.png
    │   │   └── Webserver-Status.png
    │   └── phase3/
    │       ├── deploy-phase3.png
    │       ├── Formation-Stack2.png
    │       ├── CloudFormation-Stack-Status-Check.png
    │       ├── alb-configuration1.png
    │       ├── alb-configuration2.png
    │       ├── alb-configuration3.png
    │       ├── Apache-is-working.png
    │       ├── listener-configuration.png
    │       ├── target-group.png
    │       ├── Target-Group-Health-Check.png
    │       ├── launch-template.png
    │       ├── auto-scaling-group.png
    │       ├── running-instances.png
    │       ├── target-health.png
    │       ├── scaling-policies.png
    │       └── cloudwatch-alarms.png
    │
    └── docs/
        └── README.md

---

## Phase 1 – Network Infrastructure

Build the networking foundation required for the WordPress environment.

### Implemented Components

                    Internet
                        |
                Internet Gateway
                        |
            ---------------------------
            |                         |
    Public Subnet 1         Public Subnet 2
    (Web Server)            (Load Balancer)

            |                         |
    Private Subnet 1        Private Subnet 2
    (DB / Backend)          (DB / Backend)

#### Task 1: Virtual Private Cloud (VPC)

- VPC (10.0.0.0/16)
- 2 Public Subnets
    - wordpress-public-subnet1 (10.0.1.0/24 | us-west-2a)
    - wordpress-public-subnet2 (10.0.2.0/24 | us-west-2b)
- 2 Private Subnets
    - wordpress-private-subnet1 (10.0.3.0/24 | us-west-2a)
    - wordpress-private-subnet2 (10.0.4.0/24 | us-west-2b)
- Internet Gateway
- Route Tables
- Route Table Associations

#### Task 2: Security Groups

##### WebServerSG

Allowed:
- SSH (22)
- HTTP (80)
- HTTPS (443)

##### DatabaseSG

- MySQL (3306) from WebServerSG only

##### Deployment

###### Before deploying, you need:

✔ AWS CLI installed
- aws --version

✔ AWS configured
- aws configure

You enter:
- Access Key
- Secret Key
- Region (e.g. us-west-2)
- Output format (json)

###### Deployment with AWS CLI:

Deploy VPC stack:

    #Deploy VPC stack: automatically creates the AWS resources defined therein (VPC, subnets, etc.).
    aws cloudformation create-stack `
    --stack-name wordpress-vpc `
    --template-body file://templates/network.yaml `
    --parameters file://templates/network-parameters.

    # Wait until the stack is created       
    aws cloudformation wait stack-create-complete --stack-name wordpress-vpc

    # Check status
    aws cloudformation describe-stacks --stack-name wordpress-vpc --query "Stacks[0].StackStatus"

    # Retrieve VPC ID:
    $VPC_ID = aws cloudformation describe-stacks `
    --stack-name wordpress-vpc `
    --query "Stacks[0].Outputs[?OutputKey=='VPC'].OutputValue" `
    --output text

    # Show all subnets
    aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" `
    --query "Subnets[*].[SubnetId,CidrBlock,AvailabilityZone]" --output table
        -----------------------------------------------------------
        |                     DescribeSubnets                     |
        +---------------------------+---------------+-------------+
        |  subnet-04da942dfd0eae947 |  10.0.1.0/24  |  us-west-2a |
        |  subnet-09e0ba596ed69befa |  10.0.4.0/24  |  us-west-2b |
        |  subnet-0300f2c293b238c4d |  10.0.2.0/24  |  us-west-2b |
        |  subnet-0b84d687992d9d68a |  10.0.3.0/24  |  us-west-2a |
        +---------------------------+---------------+-------------+

    # Check Internet Gateway
    aws ec2 describe-internet-gateways `
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" `
    --query "InternetGateways[*].[InternetGatewayId]" --output table
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
        -------------------------------------------------------
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

Deploy Security Groups Stack:

    # Deploy Security Groups Stack with VPC ID
    aws cloudformation create-stack `
    --stack-name wordpress-security-groups `
    --template-body file://templates/security-groups.yaml `
    --parameters ParameterKey=EnvironmentName,ParameterValue=wordpress ` ParameterKey=VPC,ParameterValue=$VPC_ID `
    --capabilities CAPABILITY_NAMED_IAM

    # Wait until the stack is created
    aws cloudformation wait stack-create-complete `
    --stack-name wordpress-security-groups

    # Check status
    aws cloudformation describe-stacks --stack-name wordpress-security-groups ` --query "Stacks[0].StackStatus"

    # List all security groups in the VPC
    aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" `
    --query "SecurityGroups[*].[GroupName,GroupId,Description]" --output table

###### Deployment with script:

-  deploy.ps1: deploys two CloudFormation stacks 

        # network infrastructure
        wordpress-network
        ├─ VPC
        ├─ Public Subnets
        ├─ Private Subnets
        └─ Route Tables

        # security groups
        wordpress-security
        └─ Security Groups

        #Result:
        - VPC
        - Public Subnets
        - Private Subnets
        - Route Tables
        - Security Groups 

##### Validation

- VPC created successfully
- Subnets created successfully
- Subnets associated correctly
- Internet connectivity verified
- Security Groups configured successfully

##### Screenshots

- VPC
- Internet-Gateway
- Subnets
- Subnet-Associations
- VPC with Subnets
- Route-Tables
- Security-Groups

---

## Phase 2 – WordPress Deployment

Deploy and automatically configure a WordPress server using CloudFormation.

### Implemented Components

#### Task 3: EC2 Instance Deployment

- Amazon Linux 2
- t2.micro
- Public Subnet
- Public IP Enabled

#### Task 4: Web Server Configuration

Installed automatically using UserData:

- Apache (httpd)
    - sudo yum update -y
    - sudo yum install -y httpd
    - sudo systemctl start httpd
    - sudo systemctl enable httpd
    - sudo systemctl status httpd

- PHP
    - sudo amazon-linux-extras enable php8.2
    - sudo yum clean metadata
    - sudo yum install -y php php-cli php-fpm php-mysqlnd php-json php-gd php-mbstring php-xml php-curl php-zip

- MariaDB
    - sudo yum install -y mariadb-server
- WordPress Dependencies
    - sudo yum install -y wget tar unzip

#### Task 5: WordPress Installation

- Download WordPress
    - cd /tmp
    - wget https://wordpress.org/latest.tar.gz
    - tar -xzf latest.tar.gz
- Deploy WordPress
    - sudo mkdir -p /var/www/html/wordpress
    - sudo cp -R wordpress/* /var/www/html/wordpress/
- Configure Permissions
    - sudo chown -R apache:apache /var/www/html/wordpress
    - sudo chmod -R 755 /var/www/html/wordpress
- Configure Apache
    - Created file:
        /etc/httpd/conf.d/wordpress.conf
        <VirtualHost *:80>
            DocumentRoot /var/www/html
            <Directory /var/www/html>
                AllowOverride All
                Require all granted
            </Directory>
        </VirtualHost>
- Restart Apache
    - sudo systemctl restart httpd

- Validation
    - Open the following URL: http://<EC2-Public-IP>/wordpress
        => The WordPress installation page should be displayed.

- Result
    - WordPress was successfully installed and accessible through the EC2 public IP address.

#### Task 6: CloudFormation Automation

UserData performs:
- Apache Installation
- PHP Installation
- WordPress Download
- Service Configuration
- Service Startup

###### Deployment with script:

-  deploy-phase2.ps1: deploys a network stack and a server stack

        # wordwordpress-network-security
        ├─ VPC
        ├─ Public Subnets
        ├─ Private Subnets
        ├─ Route Tables
        └─ Security Groups
       
        # wordpress-server
        ├─ EC2 Instance
        ├─ WordPress Installation
        ├─ EBS Volume (if configured)
        └─ Public IP Address

        Deployment Flow
        1. Deploy network and security resources.
        2. Verify deployment success.
        3. Deploy the WordPress server.
        4. Verify deployment success.
        5. Display stack outputs, including the public IP address.

##### Validation

- EC2 instance running
- Apache accessible
- WordPress installation page displayed

##### Screenshots

- EC2-Instance
- Security-ssh-access
- Apache-Working.pngg
- Wordpress-Installation.png
- Cloudformation-Stack.png

---

## Phase 3 – High Availability Architecture

Implement scalability and high availability using AWS Auto Scaling and Load Balancer services.

### Implemented Components

#### Task 7: Application Load Balancer

- Internet-facing ALB
- Multi-AZ deployment
- Listener
- Target Group

#### Task 8: Launch Template

Includes:
- Amazon Linux
- UserData Automation
- Security Group Configuration

#### Task 9: Auto Scaling Group

- Minimum: 2
- Desired: 2
- Maximum: 4

#### Task 10: ALB Integration

- Target Group Registration
- Health Checks
- Traffic Distribution

##### Task 11: Dynamic Scaling Policies

Scale-Out:
- CPU > 70%

Scale-In:
- CPU < 30%

##### Validation

- ALB DNS accessible
- Healthy Targets
- Instance replacement successful
- Scaling policies working

##### Screenshots

- Load Balancer
- Target Group
- Auto Scaling Group
- CloudWatch Alarms
- Scaling Test

---

## Deployment Steps

1. Deploy Network Stack
2. Deploy WordPress Stack
3. Deploy ALB and Auto Scaling Stack
4. Verify Infrastructure

## Validation Steps

- Verify VPC Resources
- Verify EC2 Instance
- Verify WordPress Accessibility
- Verify ALB Functionality
- Verify Auto Scaling Behaviour

## Cleanup

Delete stacks in the following order:
1. autoscaling-alb
2. wordpress-server
3. network-security