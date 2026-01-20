<#
.SYNOPSIS
    Builds 4kb Markdown files
.DESCRIPTION
    Builds 4kb Markdown files N different ways, in order to test performance.
.NOTES
    In the interests of fair play, any prerequisities should be installed before builds are timed.
#>
param()

Push-Location $PSScriptRoot

#region Install Prereqs
$null = npx @11ty/eleventy --help
#endregion Install Prereqs

& {
    foreach ($file in Get-ChildItem -filter build.with.*.ps1) {
        $techniqueName = $file.Name -replace '\.build\.with' -replace '\.ps1$'
        $time = Measure-Command { . $file.FullName } 
        [PSCustomObject]@{
            Technique = $techniqueName
            Time = $time
        }
    }
} | Tee-Object -Variable buildTimes


$buildTimes = $buildTimes | Sort-Object Time

foreach ($buildTime in $buildTimes) {
    $relativeSpeed = $buildTime.Time.TotalMilliseconds / $buildTimes[-1].Time.TotalMilliseconds
    Add-Member NoteProperty -InputObject $buildTime -Name RelativeSpeed $relativeSpeed -Force
} 

$buildTimes | ConvertTo-Html -Title BuildTimes > ./times.html

@(
    "<html>"
    "<head>"
    "<title>4kb Markdown Files</title>"
    "<style>body { height: 100vh; max-width: 100vw; margin:0 } svg { height: 25%; }</style>"
    "</head>"
    "<body>"
    foreach ($buildTime in $buildTimes) {
        "<details open>"
            "<summary>$($buildTime.Technique) ($([Math]::Round(
                $buildTime.Time.TotalSeconds, 2
            ))s)</summary>"
            "<svg xmlns='http://www.w3.org/2000/svg' width='100%' height='100%'>"
                "<rect x='0%' width='1%' height='100%'>"
                    "<animate attributeName='width' from='1%' to='$([Math]::Round($buildTime.relativeSpeed * 100, 2))%' dur='$($buildTime.Time.TotalSeconds)s' fill='freeze' />"
                "</rect>"
            "</svg>"
        "</details>"
    }
    
    "<h3>The Numbers</h3>"
    $buildTimes | ConvertTo-Html -Fragment
    "</body>"
    "</html>"
) > ./index.html


Pop-Location