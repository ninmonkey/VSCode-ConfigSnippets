﻿using namespace System.Collections.Generic
$Config = @{
    Source       = Get-Item -ea stop "$Env:APPDATA\Code\User\settings.json"
    # Dest         = Join-Path -Path '.' -ChildPath '.\exported\filtered_settings.json'
    Dest         = Join-Path -Path '.' -ChildPath '.\exported\filtered_settings.json'
    DestBasePath = '.\exported'
}
# $src = Get-Item 'C:\Users\cppmo_000\AppData\Roaming\Code\User\settings.json'
# $dest = 'C:\Users\cppmo_000\Documents\2020\MyModules_Github\VSCode-ConfigSnippets\terminal\wip_terminal_settings.json'

# $regex = 'term|console|external|integrated|debug'
# Get-Content $src
# | Where-Object { $_ -match $regex }
# | Set-Content -Path $dest

$script:Summary = [list[psobject]]::new()
function filterRegex {
    <#
    .synopsis
        simple regex filter to grab any setting related to regex
        including commented out values
    #>
    param(
        [parameter(
            Mandatory, Position = 0, HelpMessage = 'list of regex')]
        [string[]]$Regex,

        [parameter(
            Mandatory, ValueFromPipeline, HelpMessage = 'input text')]
        [AllowEmptyString()]
        [string]$InputText
    )

    process {
        # toggle modes:
        $Regex += '\{', '\}'
        $Regex += '\s*"\['
        $Regex += '\[', '\]'
        $Regex += '/\*', '\*/'
        # $Regex += '\s+//'

        if ( [string]::IsNullOrEmpty( $InputText) ) {
            return
        }
        $shouldKeep = $false
        foreach ($pattern in $Regex) {
            if ($InputText -match $pattern) {
                $shouldKeep = $true
                continue
            }
        }

        if ($shouldKeep) {
            $InputText
        }

    }
}

function Get-VSCodeConfig {
    <#
    .synopsis
        regex filter of all VS Code settings
    .description
        note: assumes file was formatted.
        does not use json parsing because that strips out comments. (maybe there's a jsonc lib)

    #>
    param(
        [parameter(

            # Mandatory,
            Position = 0,
            HelpMessage = 'list of regex')]
        [string[]]$Regex,

        [parameter(
            Position = 1,
            HelpMessage = 'Destination')]
        [string]$Destination = $Config.Dest,

        [parameter(
            Position = 2,
            HelpMessage = 'Source (if not the default path)')]
        [string]$Source = "$Env:APPDATA\Code\User\settings.json"

    )

    Process {
        $contentFiltered = Get-Content $Source
        | filterRegex -Regex $Regex

        $finalContent = @(
            # '{'
            ($contentFiltered)
            # '}'
        ) -join "`n"

        $finalContent
        | Set-Content -Path $Destination -Encoding utf8


        $metaData = [ordered]@{
            LineCount   = (Get-Content $Destination).count
            Regex       = $Regex | Join-String -Sep ', ' -SingleQuote
            Destination = $Destination
            Source      = $Source | Get-Item | Resolve-Path -Relative
        }

        if ($source -eq "$Env:APPDATA\Code\User\settings.json") {
            $metaData.Source = 'default'
        }

        $metaData | Format-Table | Out-String
        | Write-Debug

        $script:Summary.add( [pscustomobject]$metaData )

    }
}


function Main_VSCollect {
    $summary = @()
    $splat = @{
        Regex       = 'term|console|external|integrated|debug'
        # Source = 'foo' # default is user's profile
        Destination = Join-Path -Path $Config.DestBasePath -ChildPath 'terminal.json'

    }
    Get-VSCodeConfig @splat

    $splat = @{
        Regex       = 'powershell', 'pscript'
        # Source = 'foo' # default is user's profile
        Destination = Join-Path -Path $Config.DestBasePath -ChildPath 'powershell.json'
    }
    Get-VSCodeConfig @splat



    h1 'summary'
    $script:summary

}


#entry point
Main_VSCollect
| Format-List