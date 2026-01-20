param(
[Alias('Input')]
[string]
$InputPath = "$psScriptRoot/TestMarkdown",

[string]
$OutputPath = "$psScriptRoot/PowerShellForeachObject"
)


Get-ChildItem -Path $InputPath -File |
    Foreach-Object {
        $in = $_
        New-Item -ItemType File -Path (
            Join-Path $OutputPath ($in.Name -replace '\.md$') | 
            Join-Path -ChildPath ./index.html
        ) -Value (
            ($in | 
                ConvertFrom-Markdown | 
                Select-Object -ExpandProperty html) 
        ) -Force
    }
