# VM parancsok

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)
## Dokumentáció

- PowerShell és Azure-Cli: https://learn.microsoft.com/hu-hu/azure/virtual-machines/

## Parancsok

### VM lekérdezése

```powershell
Get-AzVm
```

```bash
az vm list -o table
```

### VM létrehozás

**PowerShell**

- Teljesen önálló VM létrehozása

```powershell
$eroforrascsoport='mentorklub'
$regio='Sweden Central'
$vmneve='WinServer01'
$vmmerete='Standard_B1s'
```

```powershell
New-AzResourceGroup -Location $regio -Name $eroforrascsoport
```

```powershell
New-AzVm `
    -ResourceGroupName $eroforrascsoport `
    -Name $vmneve `
    -Location $regio `
    -VirtualNetworkName "$vmneve-vnet" `
    -SubnetName 'frontend' `
    -SecurityGroupName "$vmneve-nsg" `
    -PublicIpAddressName "$vmneve-pip" `
    -Size $vmmerete `
    -OpenPorts 80,443,3389 `
    -Credential (Get-Credential)
```

_Egyéb PowerShell esetén:_
- `Get-Credential` parancs bekéri a felhasználóevet és a hozzá tartozó jelszót. Ezt teljesen biztonságosan kezeli.

**Azure-CLi**

Linux VM létrehozása, SSH kulcs generálással és saját hálózattal

```bash
eroforrascsoport='mentorklub'
regio='swedencentral'
vmneve='LinuxServer01'
vmmerete='Standard_B1s'
```

```bash
az group create -l $regio -n $eroforrascsoport
```


```bash
az vm create \
  --resource-group $eroforrascsoport \
  --name $vmneve \
  --image Ubuntu2404 \
  --vnet-name "$vmneve-net" \
  --subnet 'frontend' \
  --nsg "$vmneve-nsg" \
  --nsg-rule 'SSH' \
  --public-ip-address "$vmneve-pip" \
  --admin-username 'localadmin' \
  --generate-ssh-keys \
  --size $vmmerete \
  --public-ip-sku Standard
```

NSG nélküli gépek, létező VNET-be

```bash
eroforrascsoport='mentorklub'
regio='swedencentral'
vmneve='LinuxServer02'
vmmerete='Standard_B1s'
vnet='mentor-vnet'
subnet='frontend'
```

```bash
az group create -l $regio -n $eroforrascsoport
```

```bash
az vm create \
  --resource-group $eroforrascsoport \
  --name $vmneve \
  --image UbuntuLTS \
  --vnet-name $vnet \
  --subnet $subnet \
  --nsg '' \
  --admin-username 'localadmin' \
  --generate-ssh-keys \
  --size $vmmerete \
  --public-ip-sku Standard
```


- VM létrehozás saját képfájlból

**Linux + Apache2**

```bash
eroforrascsoport='mentorklub'
regio='swedencentral'
vmneve='WebServer01'
vmmerete='Standard_B1s'
vnet='mentor-vnet'
subnet='frontend'
```

```bash
az group create -l $regio -n $eroforrascsoport
```

```bash
az vm create \
  --resource-group $eroforrascsoport \
  --name $vmneve \
  --vnet-name $vnet \
  --subnet $subnet \
  --nsg '' \
  --admin-username 'localadmin' \
  --generate-ssh-keys \
  --size $vmmerete \
  --public-ip-sku Standard \
  --security-type TrustedLaunch \
  --image "/subscriptions/3a1ff985-e6aa-44a8-ad61-a6827fa6f92a/resourceGroups/mentorklub/providers/Microsoft.Compute/galleries/MentorKlub/images/Ubuntu24-Apache2-TesztOldal/versions/2024.10.15"
```

**Linux + Webszerver + SQL kapcsolat**

```bash
eroforrascsoport='mentorklub'
regio='swedencentral'
vmneve='WebServer02'
vmmerete='Standard_B1s'
vnet='mentor-vnet'
subnet='frontend'
```

```bash
az group create -l $regio -n $eroforrascsoport
```

```bash
az vm create \
  --resource-group $eroforrascsoport \
  --name $vmneve \
  --vnet-name $vnet \
  --subnet $subnet \
  --nsg '' \
  --admin-username 'localadmin' \
  --generate-ssh-keys \
  --size $vmmerete \
  --public-ip-sku Standard \
  --security-type TrustedLaunch \
  --image "/subscriptions/3a1ff985-e6aa-44a8-ad61-a6827fa6f92a/resourceGroups/mentorklub/providers/Microsoft.Compute/galleries/MentorKlub/images/Ubuntu24-WebApp-SQL-Kapcsolat/versions/2024.10.15"
```


_Egyéb Azure-Cli esetén:_

- `--no-wait` kapcsoló hatására a parancs a háttérben fut.
- `--generate-ssh-keys` generál saját ssh kulcsot, amit a `~/.ssh` mappába generál a parancs
- Linux gépbe való bejelentkezés: `ssh -i ~/.ssh/id_rsa localadmin@gép_ip_címe`
- Port nyitása létező VM-hez: `az vm open-port -g 'erőforráscsoport' -n 'vmneve' --port 80,443 --priority 300`
- Ubuntu verzió ellenőrzése: `lsb_release -a`

[<< Vissza](README.md)
