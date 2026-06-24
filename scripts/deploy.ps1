# Deploy Network Stack
Write-Host ""
Write-Host "Deploying Network Stack..."
Write-Host ""

aws cloudformation deploy `
--stack-name wordpress-network `
--template-file ../templates/network.yaml `
--parameter-overrides `
EnvironmentName=wordpress `
VpcCIDR=10.0.0.0/16 `
PublicSubnet1CIDR=10.0.1.0/24 `
PublicSubnet2CIDR=10.0.2.0/24 `
PrivateSubnet1CIDR=10.0.3.0/24 `
PrivateSubnet2CIDR=10.0.4.0/24

Write-Host ""
Write-Host "Network Stack Finished."
Write-Host ""

Write-Host ""
Write-Host "Deploying Security Group Stack..."
Write-Host ""

aws cloudformation deploy `
--stack-name wordpress-security `
--template-file ../templates/security-groups.yaml `
--parameter-overrides `
EnvironmentName=wordpress

Write-Host ""
Write-Host "Security Group Stack Finished."
Write-Host ""