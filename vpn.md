# VPN-hez kapcsolódó scriptek és parancsok

[![Cloud Shell indítása](https://learn.microsoft.com/azure/cloud-shell/media/embed-cloud-shell/launch-cloud-shell-1.png)](https://shell.azure.com)

## Point-To-Site VPN

Dokumentáció: https://learn.microsoft.com/hu-hu/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal

Példa beállytás:

- 172.0.0.0/24
- IKEv2, OpenVPN
- Azure Tanúsítvány

### Tanúsítványok létrehozása

1. Fő tanúsítvány:

```PowerShell
# Fájl neve: AzureRootCert.ps1
 $cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject “CN=AzureRootCert” -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation “Cert:\CurrentUser\My” -KeyUsageProperty Sign -KeyUsage CertSign 
```

2. Kliens tanúsítvány:

```PowerShell
# Fájl neve: AzureClientCert.ps1
 New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
-Subject “CN=AzureChildCert” -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation “Cert:\CurrentUser\My” `
-NotAfter (Get-Date).AddYears(6)`
-Signer $cert -TextExtension @(“2.5.29.37={text}1.3.6.1.5.5.7.3.2”) 
```

A tanúsítványok a felhasználó tanúsítvány tárolójában lesznek. A fő tanúsítványt Base64 kódolásban kell exportálni `.cer` kiterjeszésben.

Windows-on Routing menuális beállítása:

```PowerShell
route add 10.10.0.0 MASK 255.255.0.0 172.0.0.1 -p
```


[<< Vissza](README.md)
