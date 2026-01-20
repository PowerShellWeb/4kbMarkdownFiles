param(
[Alias('Input')]
[string]
$InputPath = "$psScriptRoot/TestMarkdown",

[string]
$OutputPath = "$psScriptRoot/PowerShellConvertFromMarkdown"
)


foreach ($file in Get-ChildItem -Path $InputPath -File) {
    
    $fileHtml = (ConvertFrom-Markdown -LiteralPath $file.FullName).Html
    
    $fileName = $file.Name
    
    $directoryPath = $OutputPath, ($fileName -replace '\.md$') -join '/'

    if (-not [IO.Directory]::Exists($directoryPath)) {
        $null = [IO.Directory]::CreateDirectory($directoryPath)
    }

    $fileOutputPath = $OutputPath, ($fileName -replace '\.md$'), 'index.html' -join '/'
    
    [IO.File]::WriteAllText($fileOutputPath, $fileHtml)    
}
