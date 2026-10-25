# VMSS létrehozás egyéni konfigurációval
# Indításkor bekéri az erőforráscsoport nevét, a példányszámot és a bejelentkezési adatokat,
# majd létrehozza az erőforráscsoportot, a virtuális hálózatot és a VMSS-t.

$resourceGroupName = (Read-Host "Erőforráscsoport neve (resourceGroupName)").Trim()
if ([string]::IsNullOrWhiteSpace($resourceGroupName)) {
    throw "Az erőforráscsoport neve kötelező."
}

$skuCapacityText = (Read-Host "Példányok száma (SkuCapacity)").Trim()
$skuCapacity = 0
if (-not [int]::TryParse($skuCapacityText, [ref]$skuCapacity) -or $skuCapacity -lt 1) {
    throw "A SkuCapacity pozitív egész szám legyen."
}

# Tiltott felhasználónevek: administrator, root
# Jelszó hossza minimum 12 karakter. Tartalmaznia kell: kisbetű, nagybetű, szám, speciális karakter
$credential = Get-Credential

$uniqueId = Get-Random
$scaleSetName = ("$uniqueId" + "-vmss")
$location = "Sweden Central"

# Erőforráscsoport
New-AzResourceGroup -Name $resourceGroupName -Location $location -Tag @{vmss = "$uniqueId" } | Out-Null

# Virtuális hálózat
$vnet = New-AzVirtualNetwork `
    -Name ("$uniqueId" + "-vnet") `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -AddressPrefix "10.0.0.0/16" `
    -Tag @{vmss = "$uniqueId" }

Add-AzVirtualNetworkSubnetConfig -Name "frontend" -VirtualNetwork $vnet -AddressPrefix "10.0.0.0/24" | Out-Null
Add-AzVirtualNetworkSubnetConfig -Name "backend" -VirtualNetwork $vnet -AddressPrefix "10.0.1.0/24" | Out-Null
$vnet = $vnet | Set-AzVirtualNetwork

# Hálózati biztonsági csoport: HTTP és SSH
$nsg = New-AzNetworkSecurityGroup `
    -Name ("$uniqueId" + "-nsg") `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -Tag @{vmss = "$uniqueId" }

$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "AllowHTTP" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 100 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 80 | Out-Null

$nsg | Add-AzNetworkSecurityRuleConfig `
    -Name "AllowSSH" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 110 `
    -SourceAddressPrefix Internet `
    -SourcePortRange * `
    -DestinationAddressPrefix * `
    -DestinationPortRange 22 | Out-Null

$nsg = $nsg | Set-AzNetworkSecurityGroup

Set-AzVirtualNetworkSubnetConfig `
    -VirtualNetwork $vnet `
    -Name "frontend" `
    -AddressPrefix "10.0.0.0/24" `
    -NetworkSecurityGroup $nsg | Out-Null
$vnet = $vnet | Set-AzVirtualNetwork

# Nyilvános IP cím
$publicIp = New-AzPublicIpAddress -Name ("$uniqueId" + "-pip-vmss") -ResourceGroupName $resourceGroupName -AllocationMethod Static -DomainNameLabel ("vmss" + "$uniqueId") -Sku "Standard" -Location $location -Tag @{vmss = "$uniqueId" }

## Terheléselosztó
## LB FE konfiguráció
$feipCfg = New-AzLoadBalancerFrontendIpConfig -Name ("$uniqueId" + "-lb-fe") -PublicIpAddress $publicIp

## LB BE konfiguráció
$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name ("$uniqueId" + "-lb-be")

## Health Probe a terheléselosztóhoz
$healthprobe = New-AzLoadBalancerProbeConfig -Name ("$uniqueId" + "-probe") -Protocol "http" -Port 80 -RequestPath "/" -IntervalInSeconds 15 -ProbeCount 15 -ProbeThreshold 10

## Terheléselosztási szabály
$rule = New-AzLoadBalancerRuleConfig -Name ("$uniqueId" + "-lb-rule") -FrontendIPConfiguration `
    $feipCfg -BackendAddressPool $bepool -Probe $healthprobe -Protocol Tcp `
    -FrontendPort 80 -BackendPort 80 -IdleTimeoutInMinutes 15 `
    -LoadDistribution SourceIP

# Bejövő NAT szabály
$natRuleV2HTTP = New-AzLoadBalancerInboundNatRuleConfig -Name ("$uniqueId" + "-nat-HTTP") -Protocol "Tcp" `
    -FrontendIpConfiguration $feipCfg `
    -FrontendPortRangeStart 45000 -FrontendPortRangeEnd 45050 `
    -BackendAddressPool $bepool -IdleTimeoutInMinutes 10 -BackendPort 80

$natRuleV2SSH = New-AzLoadBalancerInboundNatRuleConfig -Name ("$uniqueId" + "-nat-SSH") -Protocol "Tcp" `
    -FrontendIpConfiguration $feipCfg `
    -FrontendPortRangeStart 45100 -FrontendPortRangeEnd 45150 `
    -BackendAddressPool $bepool -IdleTimeoutInMinutes 10 -BackendPort 22

## Terheléselosztó a korábbi elemekkel és paraméterekkel
$lb = New-AzLoadBalancer -Name ("$uniqueId" + "-lb-vmss") -ResourceGroupName $resourceGroupName -Location $location `
    -FrontendIpConfiguration $feipCfg -BackendAddressPool $bepool `
    -Probe $healthprobe `
    -InboundNatRule $natRuleV2HTTP, $natRuleV2SSH `
    -LoadBalancingRule $rule `
    -Sku "Standard" `
    -Tag @{vmss = "$uniqueId" }

# VMSS konfiguráció
$vmssConfig = New-AzVmssConfig `
    -Location $location `
    -SkuCapacity $skuCapacity `
    -OrchestrationMode Uniform `
    -SkuName "Standard_B1s" `
    -UpgradePolicyMode "Automatic" `
    -SecurityType "TrustedLaunch" `
    -Tag @{vmss = "$uniqueId" }

# Cloud-Init konfiguráció
$cloudConfig = @'
#cloud-config
package_update: true
package_upgrade: true
packages:
  - apache2

write_files:
  - path: /tmp/index.html.tpl
    permissions: "0644"
    content: |
      <html><head><style>body{font-family:Verdana,Geneva,Tahoma,sans-serif;margin:0;min-height:100vh;background:radial-gradient(circle at 20% 20%,#4cc9f0,#4361ee 35%,#3a0ca3 70%,#10002b);color:#fff;text-align:center;display:grid;place-items:center}</style></head><body><h1>Web:<br />__HOSTNAME__</h1></body></html>

runcmd:
  - systemctl disable --now nginx || true
  - systemctl enable --now apache2
  - bash -lc 'HOST=$(hostname); sed "s/__HOSTNAME__/$HOST/" /tmp/index.html.tpl > /var/www/html/index.html'
  - chown www-data:www-data /var/www/html/index.html || true
  - chmod 0644 /var/www/html/index.html
'@

$cloudConfigBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($cloudConfig))

# VM image beállítása (Gen2 Ubuntu 24.04 LTS) – TrustedLaunch kompatibilis
Set-AzVmssStorageProfile $vmssConfig `
    -OsDiskCreateOption FromImage `
    -ImageReferencePublisher "Canonical" `
    -ImageReferenceOffer "ubuntu-24_04-lts" `
    -ImageReferenceSku "server" `
    -ImageReferenceVersion "latest"

# Hálózati beállítás
$subnetId = ($vnet.Subnets | Where-Object { $_.Name -eq "frontend" }).Id
$ipCfg = New-AzVmssIpConfig -Name "ipConfig" -SubnetId $subnetId -LoadBalancerBackendAddressPoolsId $lb.BackendAddressPools[0].Id -Primary

Add-AzVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmssConfig -Name "network-main" -Primary $True -IPConfiguration $ipCfg

# Felhasználói bejelentkezés
Set-AzVmssOsProfile -VirtualMachineScaleSet $vmssConfig -ComputerNamePrefix $uniqueId -AdminUsername $credential.UserName -AdminPassword $credential.Password -CustomData $cloudConfigBase64

# VMSS létrehozás
New-AzVmss `
    -ResourceGroupName $resourceGroupName `
    -Name $scaleSetName `
    -VirtualMachineScaleSet $vmssConfig

Write-Host "VMSS elérése: http://vmss$uniqueId.swedencentral.cloudapp.azure.com"
