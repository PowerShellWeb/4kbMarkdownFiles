<#
.SYNOPSIS
    Builds 4kb markdown files with astro
.DESCRIPTION
    Builds 4kb markdown files with astro.    
#>
param(
[Alias('Input')]
[string]
$InputPath = "$psScriptRoot/TestMarkdown",

[string]
$OutputPath = "$psScriptRoot/astro",

[string]
$AstroProjectRoot = "$psScriptRoot/astrodev"
)


if (-not (Test-path $AstroProjectRoot)) {
    $null = New-Item -ItemType Directory -Path $AstroProjectRoot -Force
}

Push-Location $AstroProjectRoot

@"
// @ts-check
import { defineConfig } from 'astro/config';

// https://astro.build/config
export default defineConfig($(
    [ordered]@{
        outDir = $OutputPath
    } | ConvertTo-Json
));
"@ > ./astro.config.mjs

npm run build

Pop-Location

