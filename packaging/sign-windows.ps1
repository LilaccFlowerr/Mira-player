param([Parameter(Mandatory=$true)][string]$Path)
$ErrorActionPreference = 'Stop'
if (!$env:WINDOWS_PFX_BASE64 -or !$env:WINDOWS_PFX_PASSWORD) { Write-Host 'Unsigned development build'; exit 0 }
$pfx = Join-Path $env:RUNNER_TEMP 'mira-sign.pfx'
$cert = $null
try {
    [IO.File]::WriteAllBytes($pfx, [Convert]::FromBase64String($env:WINDOWS_PFX_BASE64))
    $password = ConvertTo-SecureString $env:WINDOWS_PFX_PASSWORD -AsPlainText -Force
    $cert = Import-PfxCertificate -FilePath $pfx -CertStoreLocation Cert:\CurrentUser\My -Password $password
    $signTool = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin\*\x64\signtool.exe' | Sort-Object FullName -Descending | Select-Object -First 1
    if (!$signTool) { throw 'signtool not found' }
    & $signTool.FullName sign /sha1 $cert.Thumbprint /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $Path
    if ($LASTEXITCODE -ne 0) { throw 'Code signing failed' }
    & $signTool.FullName verify /pa $Path
    if ($LASTEXITCODE -ne 0) { throw 'Signature verification failed' }
} finally {
    Remove-Item $pfx -Force -ErrorAction SilentlyContinue
    if ($cert) { Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)" -Force }
}
