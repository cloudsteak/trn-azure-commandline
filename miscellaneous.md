# Vegyes Azure CLI és PowerShell parancsok - oktatáshoz

Ez a dokumentum alapvető Azure CLI és PowerShell parancsokat tartalmaz, amelyek segítségével megismerkedhetsz az Azure parancssori használatával.

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)

## Azure CLI parancsok

### Bejelentkezés az Azure-ba

```bash
az login
```

### Azure előfizetések listázása

```bash
az account list --output table
```

### Előfizetések csak bizonyos adatainak listázása

```bash
az account list --query "[].{Name:name, Id:id}"
```

### Adott karaktereket tartalmazó előfizetés listája

```bash
az account list --query "[?contains(name,'Azure')].{Name:name, UserName:user.name}"
```

### Aktív előfizetés váltása

```bash
az account set --subscription "Előfizetés neve vagy ID-je"
```

### Azure verzió ellenőrzése

```bash
az version
```

### Régiók listája

```bash
az account list-locations --output table
```

### Európai régiók listája

```bash
az account list-locations --query "[?contains(regionalDisplayName,'Europe')]" -o table
```

### Virtuális gép méretek adott régióban

```bash
az vm list-sizes --location 'régió' -o table
```

### Minden géptípus egy családból

```bash
az vm list-sizes --location swedencentral --query "[?starts_with(name, 'Standard_D2s')].{Name:name, Cores:numberOfCores, Memory:memoryInMB}"
```

### Teljesen önálló linux létrehozása

Linux VM létrehozása, SSH kulcs generálással és saját hálózattal

```bash
eroforrascsoport='mentorklub2025'
regio='swedencentral'
vmneve='LinuxServer01'
vmmerete='Standard_B1s'
```

```bash
az vm create \
  --resource-group $eroforrascsoport \
  --name $vmneve \
  --image Ubuntu2404 \
  --vnet-name "$vmneve-net" \
  --subnet 'alap' \
  --nsg "$vmneve-nsg" \
  --nsg-rule 'SSH' \
  --public-ip-address "$vmneve-pip" \
  --admin-username 'localadmin' \
  --generate-ssh-keys \
  --size $vmmerete \
  --public-ip-sku Standard
```

### Linux létrehozása egyedi script futtatással

```bash
eroforrascsoport='mentorklub2025'
regio='swedencentral'
vmneve='WebServer01'
vmmerete='Standard_B1s'
```

```bash
az vm create \
  --resource-group $eroforrascsoport \
  --name $vmneve \
  --image Ubuntu2404 \
  --vnet-name "$vmneve-net" \
  --subnet 'alap' \
  --nsg "$vmneve-nsg" \
  --nsg-rule 'SSH' \
  --public-ip-address "$vmneve-pip" \
  --admin-username 'localadmin' \
  --generate-ssh-keys \
  --size $vmmerete \
  --public-ip-sku Standard \
  --custom-data cloud-init.yaml
```

- Port nyitása létező VM-hez: `az vm open-port -g $eroforrascsoport -n $vmneve --port 80,443 --priority 300`

### Fájlmegosztás lépztehozása

### Fájlmegosztás létrehozása létező storage account-hoz

Linux VM-en fájlmegosztás létrehozása az Azure Files használatával egy már meglévő storage account esetén.

```bash
share_name='k-meghajto'
```

```bash
accountKey=$(az storage account keys list \
  --resource-group mentorklub2025 \
  --account-name mentorklub2025sa \
  --query "[0].value" -o tsv)

az storage share create \
  --name $share_name \
  --account-name mentorklub2025sa \
  --account-key $accountKey
```

```bash
az storage share list --account-name 'existing_storage_account_name' --output table
```

```bash
az storage file upload --share-name $share_name --source /path/to/local/file --account-name 'existing_storage_account_name'
```

## PowerShell alapparancsok Azure-hoz

### Bejelentkezés az Azure-ba

```powershell
Connect-AzAccount
```

### Azure előfizetések listázása

```powershell
Get-AzSubscription | Format-Table
```

### Előfizetések csak bizonyos adatainak listázása

```powershell
Get-AzSubscription | Select-Object @{Name='Name';Expression={$_.Name}}, @{Name='Id';Expression={$_.Id}}
```

### Adott karaktereket tartalmazó előfizetés listája

```powershell
Get-AzSubscription | Where-Object { $_.Name -like '*Azure*' } | Select-Object Name
```

### Aktív előfizetés váltása

```powershell
Set-AzContext -Subscription "Előfizetés neve vagy ID-je"
```

### Azure modul verzió ellenőrzése

```powershell
Get-Module -Name Az -ListAvailable | Select-Object Name, Version
```

### Régiók listája

```powershell
Get-AzLocation | Format-Table
```

### Virtuális gép méretek adott régióban

```powershell
Get-AzVMSize -Location 'régió' | Format-Table
```

### Minden géptípus egy családból

```powershell
Get-AzVMSize -Location 'swedencentral' |
    Where-Object { $_.Name -like 'Standard_D2s*' } |
    Select-Object @{Name='Name';Expression={$_.Name}}, @{Name='Cores';Expression={$_.NumberOfCores}}, @{Name='Memory';Expression={$_.MemoryInMB}}
```

### Teljesen önálló VM létrehozása

```powershell
$eroforrascsoport='mentorklub2025'
$regio='Sweden Central'
$vmneve='WinServer01'
$vmmerete='Standard_D2s_v5'
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
    -SubnetName 'alap' `
    -SecurityGroupName "$vmneve-nsg" `
    -PublicIpAddressName "$vmneve-pip" `
    -Size $vmmerete `
    -OpenPorts 80,443,3389 `
    -Credential (Get-Credential)
```

_Egyéb PowerShell esetén:_

- `Get-Credential` parancs bekéri a felhasználóevet és a hozzá tartozó jelszót. Ezt teljesen biztonságosan kezeli.
