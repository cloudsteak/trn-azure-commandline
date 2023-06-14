# VM parancsok

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)
## Dokumentáció

- PowerShell és Azure-Cli: https://learn.microsoft.com/hu-hu/azure/virtual-machines/

## Parancsok

- VM lekérdezése

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
    -OpenPorts 80,443,3389 `
    -Credential (Get-Credential)
```

_Egyéb PowerShell esetén:_

- `Get-Credential` parancs bekéri a felhasználóevet és a hozzá tartozó jelszót. Ezt teljesen biztonságosan kezeli.

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

_Egyéb Azure-Cli esetén:_

- `--no-wait` kapcsoló hatására a parancs a háttérben fut.
- `--generate-ssh-keys` generál saját ssh kulcsot, ami a `~/.ssh` mappába generál a parancs
- Linux gépbe való bejelentkezés: `ssh -i ~/.ssh/id_rsa localadmin@gép_ip_címe`
- Port nyitása létező VM-hez: `az vm open-port -g 'erőforráscsoport' -n 'vmneve' --port 80,443 --priority 300`

[<< Vissza](README.md)
