# =============================================
# Complete Cleanup - Delete All Stacks
# =============================================

Write-Host ""
Write-Host "====================================" -ForegroundColor Red
Write-Host " WARNING: Delete ALL resources" -ForegroundColor Red
Write-Host "====================================" -ForegroundColor Red
Write-Host ""

$response = Read-Host "Type 'DELETE' to confirm deletion of all stacks"

if ($response -ne "DELETE") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🗑️ Deleting stacks in reverse order..." -ForegroundColor Yellow

# Delete Phase 3
Write-Host "Removing HA Stack..."
aws cloudformation delete-stack --stack-name wordpress-ha
aws cloudformation wait stack-delete-complete --stack-name wordpress-ha 2>$null

# Delete Phase 2
Write-Host "Removing WordPress Server Stack..."
aws cloudformation delete-stack --stack-name wordpress-server
aws cloudformation wait stack-delete-complete --stack-name wordpress-server 2>$null

# Delete Phase 1
Write-Host "Removing Network Stack..."
aws cloudformation delete-stack --stack-name wordpress-network-security
aws cloudformation wait stack-delete-complete --stack-name wordpress-network-security 2>$null

# Delete Security Groups (if separate)
Write-Host "Removing Security Groups Stack..."
aws cloudformation delete-stack --stack-name wordpress-security 2>$null
aws cloudformation wait stack-delete-complete --stack-name wordpress-security 2>$null

Write-Host ""
Write-Host "✅ All stacks deleted successfully!" -ForegroundColor Green