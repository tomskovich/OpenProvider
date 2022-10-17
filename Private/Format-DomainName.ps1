<#
    .SYNOPSIS
    Verifies if given domain name is valid, then extracts the domain name.
    OPTIONAL: Removes domain extension for usage in search queries with multiple results.

    .EXAMPLE
    Format-DomainName -Domain 'contoso.com'

    .EXAMPLE
    Format-DomainName -Domain 'server01.contoso.com'

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://tech-tom.com / https://ucsystems.nl
#>
function Format-DomainName {
    [CmdletBinding()]
    param (
        # Domain name to parse/format
        [Parameter(Mandatory, Position=0)]
        [String] $Domain,

        # [OPTIONAL] Removes domain extension from domain
        [Switch] $RemoveExtension
    )
    
    begin {
        # Get list of valid TLD's
        if ( ! $script:Extensions) {
            $ExtensionsURL = "https://raw.githubusercontent.com/publicsuffix/list/master/public_suffix_list.dat"
            $ExtensionsRaw = Invoke-RestMethod -Uri $ExtensionsURL -Verbose:$false
            
            # Remove comments and unnecessary lines, and save to script variable for faster future runs
            $script:Extensions = $ExtensionsRaw -split "`n" | Where-Object { $_ -notlike '//*' -and $_ }
        }
    }

    process {
        # Remove 'www' from domain
        $Prefix = 'www'
        $Domain = $Domain -replace "$Prefix."

        $Valid = $false
        
        # Skip TLD verification if -RemoveExtension is passed
        if ($RemoveExtension) {
            $Valid = $true
            $Domain = $Domain -replace "$Extension"
            return $Domain
        }
        else {
            foreach ($Extension in $Extensions) {
                if ($Domain -Like "*.$Extension") {
                    $Valid = $true
                    break
                }
            }
        }
    
        if ($Valid) {
            return $Domain
        }
        else {
            throw 'Not a valid TLD/Domain name.'
        }
    }
}
