& "./update-index.ps1"

$Name = Split-Path -Path $pwd -Leaf

7z a -tzip "../$Name.op" info.toml src MacroParts fonts default-generation-options.json

Write-Host("Done!")
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")