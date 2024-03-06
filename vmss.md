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
$resourceGroupName = "mentorklub"
$uniqueId = Get-Random
$scaleSetName = ("$uniqueId" + "-vmss")
$location = "Sweden Central"
```

2. Felhasználói fiók adatai.

FONTOS:
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
   -SecurityType "TrustedLaunch" `
   -Tag @{vmss="$uniqueId"}


# Saját képfájl hivatkozás
Set-AzVmssStorageProfile $vmssConfig `
  -OsDiskCreateOption "FromImage" `
  -ImageReferenceId "/subscriptions/3a1ff985-e6aa-44a8-ad61-a6827fa6f92a/resourceGroups/mentorklub/providers/Microsoft.Compute/galleries/MentorKlub/images/Ubuntu22-Apache2-TestPage/versions/2024.02.25" 



# Hálózati beállítás
$vnet = Get-AzVirtualNetwork -Name "mentor-vnet" -ResourceGroupName $resourceGroupName;
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

Write-Host "VMSS elérése: http://vmss$uniqueId.swedencentral.cloudapp.azure.com"

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
$vmss = Get-AzVmss -ResourceGroupName "mentorklub" -VMScaleSetName "sajátvmss"

# Kívánt VM számosság beállítása
$vmss.sku.capacity = 3
Update-AzVmss -ResourceGroupName "mentorklub" -Name "sajátvmss" -VirtualMachineScaleSet $vmss
```

```bash
az vmss scale --name sajátvmss --new-capacity 3 --resource-group mentorklub --verbose
```

[<< Vissza](README.md)
