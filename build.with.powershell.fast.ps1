param(
[Alias('Input')]
[string]
$InputPath = "$psScriptRoot/TestMarkdown",

[string]
$OutputPath = "$psScriptRoot/PowerShellFast"
)


$mdPipelineBuilder = [Markdig.MarkdownPipelineBuilder]::new()
$mdPipeline = [Markdig.MarkdownExtensions]::UsePipeTables($mdPipelineBuilder).Build()

foreach ($fullPath in [IO.Directory]::EnumerateFileSystemEntries($InputPath)) {
    $fileHtml = [Markdig.Markdown]::ToHtml(
        [IO.File]::ReadAllText($fullPath), $mdPipeline
    )
    
    $fileName = @($fullPath -split '[\\/]')[-1]
    
    $directoryPath = $OutputPath, ($fileName -replace '\.md$') -join '/'

    if (-not [IO.Directory]::Exists($directoryPath)) {
        $null = [IO.Directory]::CreateDirectory($directoryPath)
    }

    $fileOutputPath = $OutputPath, ($fileName -replace '\.md$'), 'index.html' -join '/'
    
    [IO.File]::WriteAllText($fileOutputPath, $fileHtml)    
}
