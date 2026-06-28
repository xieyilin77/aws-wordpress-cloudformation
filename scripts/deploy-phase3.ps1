# =============================================
# Phase 3: High Availability Architecture
# =============================================

$NetworkStack = "wordpress-network-security"
$HAStack = "wordpress-ha"
$Environment = "wordpress"

Write-Host ""
Write-Host "===================================="
Write-Host "Phase 3: High Availability Architecture"
Write-Host "===================================="
Write-Host ""

# Check if network stack exists
Write-Host "🔍 Checking if Network Stack exists..." -ForegroundColor Yellow
$networkExists = aws cloudformation describe-stacks --stack-name $NetworkStack 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Network Stack not found. Please run Phase 1 first!" -ForegroundColor Red
    aws cloudformation deploy `
        --stack-name $NetworkStack `
        --template-file ../templates/network-security.yaml `
        --parameter-overrides EnvironmentName=$Environment `
        VpcCIDR=10.0.0.0/16 `
        PublicSubnet1CIDR=10.0.1.0/24 `
        PublicSubnet2CIDR=10.0.2.0/24 `
        PrivateSubnet1CIDR=10.0.3.0/24 `
        PrivateSubnet2CIDR=10.0.4.0/24
}

Write-Host "✅ Network Stack found!" -ForegroundColor Green
Write-Host ""

# Deploy HA Stack
Write-Host " Deploying High Availability Stack..." -ForegroundColor Yellow
Write-Host ""

aws cloudformation deploy `
--stack-name $HAStack `
--template-file ../templates/wordpress-ha.yaml `
--parameter-overrides `
EnvironmentName=$Environment `
KeyPairName=vockey `
MinSize=2 `
DesiredCapacity=2 `
MaxSize=4 `
InstanceType=t2.micro `
--capabilities CAPABILITY_IAM `
--no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host " HA Stack deployment failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check CloudFormation events:" -ForegroundColor Yellow
    aws cloudformation describe-stack-events --stack-name $HAStack --max-items 5
    exit 1
}

Write-Host "✅ High Availability Stack deployed successfully!" -ForegroundColor Green
Write-Host ""

# Get outputs
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "HA Stack Outputs" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$outputs = aws cloudformation describe-stacks `
--stack-name $HAStack `
--query "Stacks[0].Outputs" `
--output json | ConvertFrom-Json

$albDNS = ($outputs | Where-Object { $_.OutputKey -eq "LoadBalancerDNSName" }).OutputValue
$albURL = ($outputs | Where-Object { $_.OutputKey -eq "LoadBalancerURL" }).OutputValue
$asgName = ($outputs | Where-Object { $_.OutputKey -eq "AutoScalingGroupName" }).OutputValue
$tgArn = ($outputs | Where-Object { $_.OutputKey -eq "TargetGroupArn" }).OutputValue

Write-Host " ALB DNS Name: $albDNS" -ForegroundColor Green
Write-Host " ALB URL: $albURL" -ForegroundColor Green
Write-Host " Auto Scaling Group: $asgName" -ForegroundColor Green
Write-Host ""

# Wait for instances
Write-Host " Waiting 90 seconds for instances to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 90

# Show instance status
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Instance Status" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

aws autoscaling describe-auto-scaling-instances `
--query "AutoScalingInstances[?AutoScalingGroupName=='$asgName']" `
--output table

# Show target health
Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Target Group Health" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

Write-Host ""
Write-Host " WordPress HA URL: http://" -NoNewline -ForegroundColor Green
aws cloudformation describe-stacks `
    --stack-name $HAStack `
    --query "Stacks[0].Outputs[?OutputKey=='LoadBalancerURL'].OutputValue" `
    --output text
Write-Host ""

aws elbv2 describe-target-health `
--target-group-arn $tgArn `
--query "TargetHealthDescriptions" `
--output table

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Phase 3 completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host " WordPress URL: $albURL" -ForegroundColor Cyan
Write-Host " Auto Scaling Group: $asgName" -ForegroundColor Cyan
Write-Host ""
Write-Host " Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Access WordPress: $albURL" -ForegroundColor Yellow
Write-Host "  2. Complete WordPress setup" -ForegroundColor Yellow
Write-Host "  3. Take screenshots for documentation" -ForegroundColor Yellow
Write-Host ""
