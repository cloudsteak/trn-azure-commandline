# VMSS parancsok

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)

## Dokumentáció

- PowerShell: https://learn.microsoft.com/hu-hu/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-powershell
- Azure-Cli: https://learn.microsoft.com/hu-hu/cli/azure/vmss?view=azure-cli-latest

## Parancsok

### VMSS lekérdezése

```powershell
Get-AzVmss
```

```bash
az vmss list -o table
```

### VMSS létrehozás - egyszerű módszer (Azure CLI)

> Az `az vmss create` automatikusan létrehozza a VNet, Public IP, Load Balancer és NSG erőforrásokat. Az NSG azonban **nem** nyitja meg automatikusan a 80-as portot — ezt utólag kell pótolni.

```bash
RG="mentorklub2026"
LOC="swedencentral"
VMSS="demo-vmss"

az group create -n "$RG" -l "$LOC"

az vmss create \
  -g "$RG" \
  -n "$VMSS" \
  --image Ubuntu2204 \
  --instance-count 2 \
  --vm-sku Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --upgrade-policy-mode automatic \
  --custom-data cloud-init.yaml
```

Majd az auto-generált NSG-re engedélyezzük a HTTP forgalmat:

```bash
az network nsg rule create -g "$RG" --nsg-name "${VMSS}NSG" \
  -n "AllowHTTP" --priority 100 \
  --destination-port-ranges 80 --protocol Tcp \
  --access Allow --direction Inbound
```

### VMSS létrehozás egyéni konfigurációval (PowerShell)

A futtatható változat: [vmss-linux.ps1](vmss-linux.ps1). Indításkor bekéri a `resourceGroupName` és a `SkuCapacity` értékét, valamint a bejelentkezési adatokat, majd létrehozza az erőforráscsoportot, a virtuális hálózatot, a hálózati biztonsági csoportot, a terheléselosztót és a VMSS-t.

1. Változók

```powershell
# Változók definiálása
$resourceGroupName = "mentorklub2026"
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
   -SkuName "Standard_B1s" `
   -UpgradePolicyMode "Automatic" `
   -SecurityType "TrustedLaunch" `
   -Tag @{vmss="$uniqueId"}


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
$vnet = Get-AzVirtualNetwork -Name "mentor-vnet" -ResourceGroupName $resourceGroupName;
$subnetId = ($vnet.Subnets|where{$_.Name -eq "frontend"}).Id ;
$ipCfg = New-AzVmssIpConfig -Name "ipConfig" -SubnetId $subnetId -LoadBalancerBackendAddressPoolsId $lb.BackendAddressPools[0].Id -Primary;

Add-AzVmssNetworkInterfaceConfiguration -VirtualMachineScaleSet $vmssConfig -Name "network-main" -Primary $True -IPConfiguration $IPCfg


# Felhasználói bejelentkezés
Set-AzVmssOsProfile -VirtualMachineScaleSet $vmssConfig -ComputerNamePrefix $uniqueId -AdminUsername $credential.UserName -AdminPassword $credential.Password -CustomData $cloudConfigBase64


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

### Csatlakozás a VMSS-ben lévő szerverpéldányokhoz

A cím a szkript végén kiírt terheléselosztó címe, `http://` nélkül.

#### Management port-on (ssh - 22)

A belépés felhasználónévvel és jelszóval történik. Ezeket a létrehozáskor a `Get-Credential` kérte be.

Minden példány saját külső portot kap. Az első a **45100**, a második a **45101**, és így tovább.

```bash
ssh -p 45100 felhasznalonev@vmss12345.swedencentral.cloudapp.azure.com
```

Az `ssh` ezután kéri a jelszót.

#### Web protokollon (http - 80)

Az egyes példányok saját weboldala a **45000**-es porttól kezdődik. Az első a **45000**, a második a **45001**, és így tovább. A 80-as port a közös, terheléselosztott cím.

```text
http://vmss12345.swedencentral.cloudapp.azure.com:45000
```

### VMSS törlése minden erőforrással együtt

```powershell
Get-AzResource -TagValue "vmss egyedi azonosítója a fenti scriptből" | Remove-AzResource -Force
```

```bash
az group delete -n "$RG" --yes --no-wait
```

### VMSS-ben a VM-ek számának módosítása

```powershell
# VMSS letárolása
$vmss = Get-AzVmss -ResourceGroupName "mentorklub2026" -VMScaleSetName "sajátvmss"

# Kívánt VM számosság beállítása
$vmss.sku.capacity = 3
Update-AzVmss -ResourceGroupName "mentorklub2026" -Name "sajátvmss" -VirtualMachineScaleSet $vmss
```

```bash
az vmss scale --name sajátvmss --new-capacity 3 --resource-group mentorklub2026 --verbose
```

### SSH kulcs utólagos hozzáadása

Meglévő nyilvános kulcsot töltünk fel, új kulcsot nem generálunk. A `publikusKulcs` egy már kész `.pub` fájl, például `~/.ssh/id_rsa.pub`. A felhasználónév az, amit a `Get-Credential` kért. A jelszavas belépés megmarad.

```bash
RG="mentorklub2026"
VMSS="sajátvmss"
FELHASZNALO="felhasznalonev"
PUBLIKUS_KULCS="$HOME/.ssh/id_rsa.pub"
```

```bash
cat > ssh-key.json <<EOF
{
  "username": "$FELHASZNALO",
  "ssh_key": "$(cat "$PUBLIKUS_KULCS")"
}
EOF
```

```bash
az vmss extension set \
  --resource-group "$RG" \
  --vmss-name "$VMSS" \
  --name VMAccessForLinux \
  --publisher Microsoft.OSTCExtensions \
  --version 1.5 \
  --protected-settings ssh-key.json
```

```bash
az vmss update-instances \
  --resource-group "$RG" \
  --name "$VMSS" \
  --instance-ids "*"
```

```powershell
$eroforrascsoport = "mentorklub2026"
$vmssneve = "sajátvmss"
$felhasznalo = "felhasznalonev"
$publikusKulcs = "$HOME/.ssh/id_rsa.pub"

$sshKey = (Get-Content -Path $publikusKulcs -Raw).Trim()
$vmss = Get-AzVmss -ResourceGroupName $eroforrascsoport -VMScaleSetName $vmssneve

Add-AzVmssExtension `
    -VirtualMachineScaleSet $vmss `
    -Name "VMAccessForLinux" `
    -Publisher "Microsoft.OSTCExtensions" `
    -Type "VMAccessForLinux" `
    -TypeHandlerVersion "1.5" `
    -ProtectedSetting @{ username = $felhasznalo; ssh_key = $sshKey }

Update-AzVmss -ResourceGroupName $eroforrascsoport -Name $vmssneve -VirtualMachineScaleSet $vmss
Update-AzVmssInstance -ResourceGroupName $eroforrascsoport -VMScaleSetName $vmssneve -InstanceId "*"
```

Ezután a meglévő privát kulccsal is lehet belépni:

```bash
ssh -i "${PUBLIKUS_KULCS%.pub}" -p 45100 "$FELHASZNALO"@vmss12345.swedencentral.cloudapp.azure.com
```

[<< Vissza](README.md)
