# Parancssori eszközök Azure-hoz

Segédanyag a Gerilla Mentok Klub Azure szolgáltatások és megoldások a mindennapokban (6 hetes) képzéshez

## PowerShell

### Ismerető

A "hatalom kagyló" a Windows elsőszámű parancssori eszköze. Nagyon hasznos és minden Windows-os erőforrást kezelhetünk vele.

Rengetek modul érhető el hozzá, többek között a számunkra érdekes Azure is.

### Telepítés

Az Azure modul telepítése az alábbi cikkből egyreűen elvégezhető: https://learn.microsoft.com/hu-hu/powershell/azure/install-az-ps?view=azps-9.5.0

Mivel segádanyagról beszélünk, így röviden ide kiemelem a telepítési parancsokat. Ezekkel könnyedén telepíthetjük Windows operációs rendszerünkre. (nehézség esetén olvassuk el a fenti cikket)

```powershell
$PSVersionTable.PSVersion
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -Confirm:$false
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

_Megjegyzés: A telepítés akár 10-15 percig is eltarthat_

### Kapcsolódás Azure Tenant-hoz (illetve subscription-höz)

Miután az Azure modult telepítettük, egyszerűen futtassuk az alábbi parancsot egy PowerShell ablakban.

```powershell
Connect-AzAccount
```

Ekkor ablakban megnyílik a bejelentkező felület, ahol be tudunk jelentkezni. Ha sikerül, akkor az ablak bezáródik és visszatérünk a PowerShell ablakba.

### Előfizetések listázása

```powershell
Get-AzSubscription
```

## Azure-Cli

Az Azure elsőszámú, platform független parancssori eszköze. Ténylegesen minden platfomon futtatható: Windows, MacOS, Linux, Unix, Docker

### Telepítés

Az Azure-Cli telepítése az alábbi cikkből egyreűen elvégezhető: https://learn.microsoft.com/hu-hu/cli/azure/install-azure-cli

Nézzünk néhány tipukus telepítési parancsot

#### Windows

- Telepítési cikk: https://learn.microsoft.com/hu-hu/cli/azure/install-azure-cli-windows?tabs=azure-cli
- Telepítési állomány: https://aka.ms/installazurecliwindows

#### MacOS

- Telepítési cikk: https://learn.microsoft.com/hu-hu/cli/azure/install-azure-cli-macos
- Telepítés:

```zsh
brew update && brew install azure-cli
```

#### Ubuntu Linux

- Telepítési cikk: https://learn.microsoft.com/hu-hu/cli/azure/install-azure-cli-linux?pivots=apt
- Telepítés:

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Azure-Cli verzió elennőrzése

```bash
az version
```

vagy

```bash
az -v
```

### Kapcsolódás Azure Tenant-hoz (illetve subscription-höz)

```bash
az login
```

Ekkor ablakban megnyílik a bejelentkező felület, ahol be tudunk jelentkezni. Ha sikerül, akkor az ablak bezáródik és visszatérünk a terminál ablakba.

### Előfizetések listázása

```powershell
az account list -o table
```
