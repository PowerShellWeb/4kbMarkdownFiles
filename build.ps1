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
    "</head>"
    "<body>"
    $buildTimes | ConvertTo-Html -Fragment
    "</body>"
    "</html>"
) > ./index.html


Pop-Location