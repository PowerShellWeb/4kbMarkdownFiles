<#
.SYNOPSIS
    Builds 4kb markdown files with 11ty
.DESCRIPTION
    Builds 4kb markdown files with 11ty.
    
#>
Push-Location $PSScriptRoot

npx @11ty/eleventy --input=./TestMarkdown/*.md --output ./11ty/

Pop-Location

