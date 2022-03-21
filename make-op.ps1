& "./update-index.ps1"

$compress = @{
    Path = "./info.toml", "./src", "./MacroParts", "./fonts", "./default-generation-options.json"
    CompressionLevel = "Fastest"
    DestinationPath = "../temp.zip"
}
Compress-Archive @compress -Force

Move-Item -Path "../temp.zip" -Destination "../MacroTrackGenerator.op" -Force

Write-Host("Done!")