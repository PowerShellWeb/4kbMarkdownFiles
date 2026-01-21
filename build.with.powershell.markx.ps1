param(
[Alias('Input')]
[string]
$InputPath = "$psScriptRoot/TestMarkdown",

[string]
$OutputPath = "$psScriptRoot/PowerShellMarkX"
)


foreach ($fullPath in [IO.Directory]::EnumerateFileSystemEntries($InputPath)) {
    $markx = markx ([IO.File]::ReadAllText($fullPath))
    
    $fileName = @($fullPath -split '[\\/]')[-1]
    
    $directoryPath = $OutputPath, ($fileName -replace '\.md$') -join '/'

    if (-not [IO.Directory]::Exists($directoryPath)) {
        $null = [IO.Directory]::CreateDirectory($directoryPath)
    }

    $fileOutputPath = $OutputPath, ($fileName -replace '\.md$'), 'index.html' -join '/'
    
    [IO.File]::WriteAllText($fileOutputPath, $markx.html)    
}
