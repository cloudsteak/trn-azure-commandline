# VMSS parancsok

## Dokumentáció

- PowerShell dokumentáció: https://learn.microsoft.com/hu-hu/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-manage-powershell
- Azure-Cli dokumentáció: https://learn.microsoft.com/hu-hu/cli/azure/vmss?view=azure-cli-latest

## Parancsok

- VMSS lekérdezése

```powershell
Get-AzVmss
```

```bash
az vmss list -o table
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