# aws-wordpress-cloudformation

Prerequisites:
- Account with appropriate permissions
- AWS CLI installed and configured
- VS Code with AWS Toolkit extension (optional)
- IAM User with CloudFormation full access

1. AWS account and access credentials
    # Check if AWS CLI is installed
    aws --version
    # Configure AWS CLI (if not already done)
    aws configure

2. Create architecture diagram

3. Create directory structure
    wordpress-cloudformation/
    ├── templates/
    |── architecture_diagrams
    |── scripts
    |── screenshots

4. Creating cloudFormation templates
    - vpc.yaml
    - security-groups.yaml
    - wordpress-server.yaml

5. Deployment with AWS CLI
    - Deploy VPC stack: automatically creates the AWS resources defined therein (VPC, subnets, etc.).
        aws cloudformation create-stack `
        --stack-name wordpress-vpc `
        --template-body file://templates/vpc.yaml `
        --parameters file://templates/vpc-parameters.
        
        aws cloudformation wait stack-create-complete --stack-name wordpress-vpc

        aws cloudformation describe-stacks --stack-name wordpress-vpc --query "Stacks[0].StackStatus"

6. Deploy the VPC stack
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

7. Deploy Security Groups Stack
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

8. Verify security groups
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