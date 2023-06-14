# VMSS parancsok

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)

## Dokumentáció

- PowerShell: https://learn.microsoft.com/hu-hu/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-powershell
- Azure-Cli: https://learn.microsoft.com/hu-hu/cli/azure/vmss?view=azure-cli-latest

## Parancsok

- VMSS lekérdezése

```powershell
Get-AzVmss
```

```bash
az vmss list -o table
```

- VMSS létrehozás - saját képfájlból

1. Változók

```powershell
# Változók definiálása
$resourceGroupName = "mentorklub2023"
$uniqueId = Get-Random
$scaleSetName = ("$uniqueId" + "-vmss")
$location = "North Europe"
```

2. Felhasználói fiók adatai.

**FONTOS: **

- Tiltott felhasználó nevek: administrator, root
- Jelszó hossza minimum 12 karakter. Taertalmaznia kell: kis betű, nagy betű, szám, speciális karakter

```powershell
# Felhasználói adatok
$credential = Get-Credential
```

3. Nyílvános IP cím

```powershell
# Nyílvános IP cím
$publicIp = New-AzPublicIpAddress -Name ("$uniqueId" + "-pip-vmss") -ResourceGroupName $resourceGroupName -AllocationMethod Static -DomainNameLabel ("vmss" + "$uniqueId") -Sku "Standard" -Location $location -Tag @{vmss="$uniqueId"}
```

4. Terheléselosztó

```powershell
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
    -FrontendPortRangeStart 50000 -FrontendPortRangeEnd 50050 `
    -BackendAddressPool $bepool -IdleTimeoutInMinutes 30 -BackendPort 80

$natRuleV2SSH = New-AzLoadBalancerInboundNatRuleConfig -Name ("$uniqueId" + "-nat-SSH") -Protocol "Tcp" `
    -FrontendIpConfiguration $feipCfg `
    -FrontendPortRangeStart 51000 -FrontendPortRangeEnd 51050 `
    -BackendAddressPool $bepool -IdleTimeoutInMinutes 30 -BackendPort 22

## Terheléselosztó a korábbi elemekkel és paraméterekkel
$lb = New-AzLoadBalancer -Name ("$uniqueId" + "-lb-vmss") -ResourceGroupName $resourceGroupName -Location $location `
    -FrontendIpConfiguration $feipCfg -BackendAddressPool $bepool `
    -Probe $healthprobe `
    -InboundNatRule $natRuleV2HTTP,$natRuleV2SSH `
    -LoadBalancingRule $rule `
    -Sku "Standard" `
    -Tag @{vmss="$uniqueId"}
```

5. Virtual Machine Scale Set

```powershell
# VMSS konfiguráció
$vmssConfig = New-AzVmssConfig `
   -Location $location `
   -SkuCapacity 2 `
   -OrchestrationMode Uniform `
   -SkuName "Standard_B1ls" `
   -UpgradePolicyMode "Automatic" `
   -Tag @{vmss="$uniqueId"}


# Saját képfájl hivatkozás
Set-AzVmssStorageProfile $vmssConfig `
  -OsDiskCreateOption "FromImage" `
  -ImageReferenceId "/subscriptions/3a1ff985-e6aa-44a8-ad61-a6827fa6f92a/resourceGroups/mentorklub2023/providers/Microsoft.Compute/galleries/CloudSteak/images/Ubuntu20.04-Apache2"


# Hálózati beállítás
$vnet = Get-AzVirtualNetwork -Name "mentor-net" -ResourceGroupName $resourceGroupName;
$subnetId = ($vnet.Subnets|where{$_.Name -eq "frontend"}).Id ;
$ipCfg = New-AzVmssIpConfig -Name "ipConfig" -SubnetId $subnetId -LoadBalancerBackendAddressPoolsId $lb.BackendAddressPools[0].Id -Primary;
Add-AzVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmssConfig -Name "network-main" -Primary $True -IPConfiguration $IPCfg


# Felhasználói bejelentkezés
Set-AzVmssOsProfile -VirtualMachineScaleSet $vmssConfig -ComputerNamePrefix $uniqueId -AdminUsername $credential.UserName -AdminPassword $credential.Password


# VMSS létrehozás
New-AzVmss `
  -ResourceGroupName $resourceGroupName `
  -Name $scaleSetName `
  -VirtualMachineScaleSet $vmssConfig

Write-Host "VMSS elérése: http://vmss$uniqueId.northeurope.cloudapp.azure.com/hostname.html"

```

```bash
az vmss list -o table
```

- VMSS törlése minden erőforrással együtt

```powershell
Get-AzResource -TagValue "vmss egyedi azonosítója a fenti scriptből" | Remove-AzResource -Force
```

- VMSS-ben a VM-ek számának módosítása

```powershell
# VMSS letárolása
$vmss = Get-AzVmss -ResourceGroupName "erőforráscsoportnév" -VMScaleSetName "sajátvmss"

# Kívánt VM számosság beállítása
$vmss.sku.capacity = 3
Update-AzVmss -ResourceGroupName "erőforráscsoportnév" -Name "sajátvmss" -VirtualMachineScaleSet $vmss
```

```bash
az vmss scale --name sajátvmss --new-capacity 3 --resource-group erőforráscsoportnév --verbose
```

[<< Vissza](README.md)
