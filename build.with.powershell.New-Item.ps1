param(
[Alias('Input')]
[string]
$InputPath = "$psScriptRoot/TestMarkdown",

[string]
$OutputPath = "$psScriptRoot/PowerShellSlowest"
)


foreach ($file in Get-ChildItem -Path $InputPath -File) {
    
    $fileHtml = (ConvertFrom-Markdown -LiteralPath $file.FullName).Html
    
    $fileName = $file.Name
        
    $fileOutputPath = 
        Join-Path $OutputPath ($fileName -replace '\.md$') | 
            Join-Path -ChildPath ('index.html')

    New-Item -ItemType File -Path $fileOutputPath -Value $fileHtml -Force    
}
