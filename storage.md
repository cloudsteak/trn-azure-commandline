# Storage parancsok

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)

## Dokumentáció

- Tárfiók: https://learn.microsoft.com/hu-hu/azure/storage/common/storage-account-overview

## Parancsok

### Tárfiókok listázása

```powershell
Get-AzStorageAccount
```

```bash
az storage account list -o table
```

### Tárfiók létrehozása

```powershell


# Adatok beállítása
$resourceGroup = "mentorklub2025"
$location = "Sweden Central"

# Egyedi név generálása kisbetűkkel és számokkal
$randomName = -join ((97..122) + (48..57) | Get-Random -Count 10 | ForEach-Object {[char]$_})
$storageAccountName = "tarfiok$randomName"

New-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2
```

```bash
# Adatok beállítása
resourceGroup="mentorklub2025"
location="swedencentral"

# Egyedi név generálása kisbetűkkel és számokkal
storageAccountName="tarfiok$(tr -dc 'a-z0-9' < /dev/urandom | head -c 10)"

az storage account create --name $storageAccountName --resource-group $resourceGroup --location $location --sku Standard_LRS --kind StorageV2
```

### Blob tároló (container) létrehozása

```powershell
$containerName = "kepek"
New-AzStorageContainer -Name $containerName -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName).Context
```

```bash
containerName="kepek"
az storage container create --name $containerName --account-name $storageAccountName
```

### Helyi fájl feltöltése blob tárolóba

```powershell
Set-AzStorageBlobContent -File ".\kubernetes.webp" -Container $containerName -Blob "kubernetes.webp" -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name "$storageAccountName").Context
```

```bash
az storage blob upload --account-name $storageAccountName --container-name $containerName --name felho.webp --file "./felho.webp"
```

### Fájlmegosztás létrehozása tárfiókon belül

```powershell
$shareName = "kmeghajto"
New-AzStorageShare -Name $shareName -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name "$storageAccountName").Context
```

```bash
az storage share create --name "kmeghajto" --account-name $storageAccountName
```

### SAS token létrehozása

```powershell
New-AzStorageBlobSASToken -Container $containerName -Blob "kubernetes.webp" -Permission r -Context (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name "$storageAccountName").Context -ExpiryTime (Get-Date).AddHours(168)


```

```bash
az storage blob generate-sas \
    --account-name $storageAccountName \
    --container-name $containerName \
    --name "felho.webp" \
    --permissions r \
    --expiry $(date -u -d "168 hour" '+%Y-%m-%dT%H:%MZ') \
    --output tsv
```
