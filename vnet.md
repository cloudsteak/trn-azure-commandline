# Virtuális hálózat parancsok

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)
## Dokumentáció

- PowerShell: https://learn.microsoft.com/en-us/azure/virtual-network/quick-create-powershell
- Azure-Cli: https://learn.microsoft.com/en-us/azure/virtual-network/quick-create-cli

## Parancsok

- VNET lekérdezése

```powershell
Get-AzVirtualNetwork
```

```bash
az network vnet list
```

- VNET létrehozás

```powershell
$rg = @{
    Name = 'erőforráscsoport'
    Location = 'régió'
}
New-AzResourceGroup @rg

$vnet = @{
    Name = 'VNet név'
    ResourceGroupName = 'erőforráscsoport'
    Location = 'régió'
    AddressPrefix = '10.0.0.0/16'
}

$subnetfe = @{
    Name = 'frontend'
    VirtualNetwork = $virtualNetwork
    AddressPrefix = '10.0.0.0/24'
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnetfe

$subnetbe = @{
    Name = 'backend'
    VirtualNetwork = $virtualNetwork
    AddressPrefix = '10.0.1.0/24'
}
$subnetConfig = Add-AzVirtualNetworkSubnetConfig @subnetbe

$virtualNetwork | Set-AzVirtualNetwork
```

```bash
az group create --name 'erőforráscsoport' --location 'régó'

az network vnet create \
  --name 'VNet név' \
  --resource-group 'erőforráscsoport' \
  --address-prefix 10.0.0.0/16 \
  --subnet-name frontend \
  --subnet-prefixes 10.0.0.0/24

az network vnet subnet create -g 'erőforráscsoport' --vnet-name 'VNet név' -n backend --address-prefixes 10.0.1.0/24
```

[<< Vissza](README.md)
