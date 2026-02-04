<#
.SYNOPSIS
    Builds 4kb Markdown files
.DESCRIPTION
    Builds 4kb Markdown files N different ways, in order to test performance.
.NOTES
    In the interests of fair play, any prerequisities should be installed before builds are timed.    
#>
param(
[uri]
$BuildTimeHistoryUrl = "https://4kb.powershellweb.com/history.json"
)

# Make sure we're in the right place.
Push-Location $PSScriptRoot

$initStart = [DateTime]::Now

#region Install Prereqs
if ($env:GITHUB_WORKFLOW) {
    # Install 11ty to reduce 11ty build time
    $null = sudo npm install -g '@11ty/eleventy'    

    #region Astro Initialization
    # Install Astro to reduce astro build time
    $null = sudo npm install -g 'astro'

    $astroDevRoot = Join-Path $PSScriptRoot "astrodev"
    New-Item -ItemType File -Path (
        Join-Path $astroDevRoot package.json
    ) -Force -Value (    
        [Ordered]@{
            name='astro-test'
            type='module'
            version='0.0.1'
            scripts = [Ordered]@{
                "build" = "astro build"
            }
            dependencies = @{
                "astro" = 'latest'
            }
        } | ConvertTo-Json 
    )

    Push-Location $astroDevRoot

    npm install | Out-Host

    $pagesRoot = Join-Path $astroDevRoot "src/pages"
    if (-not (Test-Path $pagesRoot)) {
        New-Item -ItemType Directory -Path $pagesRoot
    }

    Copy-Item ../TestMarkdown/* $pagesRoot  

    Pop-Location

    #endregion Astro Initialization

    Install-Module MarkX -Force

    Import-Module MarkX -Global
}
$initEnd = [DateTime]::Now
#endregion Install Prereqs

#region Get Clock Speed
$cpuSpeed = 
    if ($executionContext.SessionState.PSVariable.Get('IsLinux').Value) {
        Get-Content /proc/cpuinfo -Raw -ErrorAction SilentlyContinue | 
            Select-String "(?<Unit>Mhz|MIPS)\s+\:\s+(?<Value>[\d\.]+)" | 
            Select-Object -First 1 -ExpandProperty Matches |
            ForEach-Object {
                $_.Groups["Value"].Value -as [int]
            }
    } elseif ($executionContext.SessionState.PSVariable.Get('IsMacOS').Value) {
        (sysctl -n hw.cpufrequency) / 1e6 -as [int]
    } else {
        $getCimInstance = $ExecutionContext.SessionState.InvokeCommand.GetCommand('Get-CimInstance','Cmdlet')
        if ($getCimInstance) {
            & $getCimInstance -Class Win32_Processor |
                Select-Object -ExpandProperty MaxClockSpeed
        }
    }
#endregion

$mySelf = $MyInvocation.MyCommand.ScriptBlock
$StartTime = [DateTime]::Now

& {
    foreach ($file in Get-ChildItem -filter build.with.*.ps1) {
        $techniqueName = $file.Name -replace '\.build\.with' -replace '\.ps1$'
        $script = (Get-Command $file.FullName -CommandType ExternalScript).ScriptBlock
        $time = Measure-Command { . $file.FullName } 
        [PSCustomObject]@{
            Technique = $techniqueName
            Time = $time
            Script = $script
        }
    }
} | Tee-Object -Variable buildTimes


$buildTimes = $buildTimes | Sort-Object Time

foreach ($buildTime in $buildTimes) {
    $relativeSpeed = $buildTime.Time.TotalMilliseconds / $buildTimes[-1].Time.TotalMilliseconds
    Add-Member NoteProperty -InputObject $buildTime -Name RelativeSpeed $relativeSpeed -Force
    Add-Member NoteProperty -InputObject $buildTime -Name DateTime $StartTime -Force
}

$history = @(try {
    Invoke-RestMethod -Uri $BuildTimeHistoryUrl -ErrorAction Ignore
} catch {}) -ne $null

$buildTimes | ConvertTo-Html -Title BuildTimes > ./times.html


$descriptionMessage = @(foreach ($buildtime in $buildTimes) {    
    ($buildTime.Technique, $buildTime.Time -join ':')    
}) -join [Environment]::NewLine

@(
    "<html>"
    
    "<head>"    
    
    "<title>4kb Markdown Files</title>"
    
    "<meta name='viewport' content='width=device-width, initial-scale=1, minimum-scale=1.0' />"

    "<meta name='og:title' content='4kb Markdown Files Benchmark' />"
    
    "<meta name='og:description' content='
4kb Markdown Files Benchmark. 
The fastest framework is no framework.
$([Web.HttpUtility]::HtmlAttributeEncode($descriptionMessage))
' />"

    "<meta name='article:published_time' content='$($StartTime.ToString('s'))' />"

    "<style>"
    
    "
    
    body { height: 100vh; max-width: 100vw; margin:0 } 
    
    svg { height: 5%; }
    h1,h2, h3,h4 { text-align: center; }
    .techniqueSummary { font-size: 2rem; }

    "
    "</style>"
    "</head>"
    "<body>"
    "<h1>4kb Markdown Files Benchmark</h1>"
    "<h2>Time to build 4096 markdown files</h2>"    
    "<h3>Last built at $([DateTime]::UtcNow.ToString("s")) running @ $cpuSpeed Mhz</h3>"
    "<h4><a href='https://github.com/PowerShellWeb/4kbMarkdownFiles/'><button>Github Repo</button></a></h4>"
    
    foreach ($buildTime in $buildTimes) {
        $green = [byte][Math]::Floor(
            (1 - $buildTime.RelativeSpeed) * 255  
        )
        $red = [byte][Math]::Floor(
            $buildTime.RelativeSpeed * 255  
        )
        $color = "#{0:x2}{1:x2}00" -f $red, $green

        "<details open>"
            "<summary class='techniqueSummary'>$($buildTime.Technique) ($([Math]::Round(
                $buildTime.Time.TotalSeconds, 2
            ))s)</summary>"
            "<details>"
            "<summary>Build Script</summary>"
            "<pre><code class='langauge-PowerShell'>"
            [Web.HttpUtility]::HtmlEncode($buildTime.Script)
            "</code></pre>"
            "</details>"
            "<svg xmlns='http://www.w3.org/2000/svg' width='100%' height='100%'>"
                "<rect x='0%' width='1%' height='100%' fill='$color' stroke='currentColor'>"
                    "<animate attributeName='width' from='1%' to='100%' dur='$($buildTime.Time.TotalSeconds)s' fill='freeze' />"
                "</rect>"
            "</svg>"
        "</details>"
    }
    
    "<h3>The Numbers</h3>"
    $buildTimes | 
        Select-Object Technique, Time, RelativeSpeed | 
        ConvertTo-Html -Fragment
    "<details>"
        "<summary>View Source</summary>"
        "<pre><code class='language-PowerShell'>"
        [Web.HttpUtility]::HtmlEncode("$mySelf")
        "</code></pre>"
    "</details>"
    "</body>"
    "</html>"
) > ./index.html

foreach ($buildTime in $buildTimes) {
    Add-Member NoteProperty -InputObject $buildTime -Name Time "$($buildTime.Time)" -Force
}

$history = @(try {
    Invoke-RestMethod -Uri $BuildTimeHistoryUrl -ErrorAction Ignore
} catch {}) -ne $null

$history += $buildTimes | 
    Select-Object Technique, Time, RelativeSpeed, DateTime

ConvertTo-Json -InputObject $history > ./history.json -Depth 2

Remove-Item -Recurse -Force ./astrodev

Pop-Location