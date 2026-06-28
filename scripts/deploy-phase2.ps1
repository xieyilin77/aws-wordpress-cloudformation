# =============================================
# Phase 2: WordPress Server Deployment mit Validierung
# =============================================

$NetworkStack = "wordpress-network-security"
$ServerStack = "wordpress-server"
$Environment = "wordpress"

Write-Host ""
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Phase 2: WordPress Server Deployment" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# 1. Network Stack deployen
Write-Host "Deploying Network Stack..." -ForegroundColor Yellow
aws cloudformation deploy `
--stack-name $NetworkStack `
--template-file ../templates/network-security.yaml `
--parameter-overrides `
EnvironmentName=$Environment `
VpcCIDR=10.0.0.0/16 `
PublicSubnet1CIDR=10.0.1.0/24 `
PublicSubnet2CIDR=10.0.2.0/24 `
PrivateSubnet1CIDR=10.0.3.0/24 `
PrivateSubnet2CIDR=10.0.4.0/24 `
--no-fail-on-empty-changeset

if ($LASTEXITCODE -ne 0) {
    Write-Host "Network deployment failed."
    exit 1
}

Write-Host ""
Write-Host "Network Stack deployed successfully."
Write-Host ""

# 2. WordPress Stack deployen
Write-Host "===================================="
Write-Host "Deploying WordPress Stack"
Write-Host "===================================="
Write-Host ""

aws cloudformation deploy `
--stack-name $ServerStack `
--template-file ../templates/wordpress-server.yaml `
--parameter-overrides `
EnvironmentName=$Environment `
KeyPairName=vockey `
--no-fail-on-empty-changeset `
--capabilities CAPABILITY_IAM

if ($LASTEXITCODE -ne 0) {
    Write-Host "WordPress deployment failed."
    exit 1
}

Write-Host ""
Write-Host "WordPress Stack deployed successfully."
Write-Host ""

Write-Host ""
Write-Host "===================================="
Write-Host "Getting Public IP"
Write-Host "===================================="
Write-Host ""

# Stack-Outputs abrufen
$outputs = aws cloudformation describe-stacks `
--stack-name $ServerStack `
--query "Stacks[0].Outputs" `
--output json | ConvertFrom-Json

$publicIP = ($outputs | Where-Object { $_.OutputKey -eq "PublicIP" }).OutputValue
$wordpressURL = ($outputs | Where-Object { $_.OutputKey -eq "WordPressURL" }).OutputValue

Write-Host "✅ Public IP: $publicIP" -ForegroundColor Green
Write-Host "✅ WordPress URL: $wordpressURL" -ForegroundColor Green
Write-Host ""

Write-Host "===================================="
Write-Host "Deployment Summary"
Write-Host "===================================="
Write-Host ""
Write-Host "WordPress URL: $wordpressURL" -ForegroundColor Cyan
Write-Host "SSH Command: ssh -i vockey.pem ec2-user@$publicIP" -ForegroundColor Green
Write-Host ""

Write-Host "WordPress might take a few minutes to be fully ready..." -ForegroundColor Yellow
Write-Host "Check Apache status: sudo systemctl status httpd" -ForegroundColor Yellow