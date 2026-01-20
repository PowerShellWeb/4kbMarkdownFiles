Push-Location $PSScriptRoot
if (Test-Path ./TestMarkdown) {
    Remove-Item -Recurse -Force ./TestMarkdown
}
$null = New-Item ./TestMarkdown -ItemType Directory -Force

$start = [datetime]::now
$random = [Random]::new()

$jumbled = foreach ($n2 in 1..16) {
    @(foreach ($n in 1..4) {
        'words', 'in', 'random', 'order' | Get-Random -Count 4
    }) | Get-Random -Count 16
}
foreach ($n in 1..4kb) {
    @(
        "# Markdown file $n"
        
        "* This is test markdown file # $n"

        "## Bingo Card"
        
        @(
            "|b|i|n|g|o|"
            "|-|-|-|-|-|"
            foreach ($row in 1..5) {
                "|$(@(
                    foreach ($n in 1..5) {
                        $random.Next(1,75)
                    }
                ) -join '|')|"
            }
        ) -join [Environment]::NewLine
            
        "What follows are $($count = $random.Next(128,256); $count) $(            
            @('words', 'in', 'random', 'order') * $count | Get-Random -Count (4 * $count)
        )"
        
        
    ) -join ([Environment]::NewLine * 2) > "./TestMarkdown/$("{0:d4}" -f $n).md"
}

$end = [DateTime]::now

$took = $end - $start

"4kb Markdown files made in $took"

Pop-Location