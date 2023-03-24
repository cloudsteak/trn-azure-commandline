# VM parancsok

## Dokumentáció

- PowerShell és Azure-Clidokumentáció: https://learn.microsoft.com/hu-hu/azure/virtual-machines/

## Parancsok

- VMSS lekérdezése

```powershell
Get-AzVm
```

```bash
az vm list -o table
```

- VM létrehozás

```powershell
New-AzVm `
    -ResourceGroupName 'erőforráscsoport' `
    -Name 'vmneve' `
    -Location 'North Europe' `
    -VirtualNetworkName 'mentor-net' `
    -SubnetName 'frontend' `
    -SecurityGroupName 'nsgneve' `
    -PublicIpAddressName 'publikusipneve' `
    -Size 'Standard_B1s'`
    -OpenPorts 80,3389
```

```bash
az vm create \
  --resource-group 'erőforráscsoport' \
  --name 'vmneve' \
  --image UbuntuLTS \
  --vnet-name 'mentor-net' \
  --subnet 'frontend' \
  --admin-username 'localadmin' \
  --generate-ssh-keys \
  --size 'Standard_B1s' \
  --public-ip-sku Standard
```

[<< Vissza](README.md)
