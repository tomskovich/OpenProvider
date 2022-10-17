<#
    .SYNOPSIS
    Retrieves/verifies Bearer token for OpenProvider API authentication

    .LINK
    https://support.openprovider.eu/hc/en-us/articles/360025683173-Getting-started-with-Openprovider-API

    .EXAMPLE
    Get-OPBearerToken

    .NOTES
    Author:   Tom de Leeuw
    Website:  https://tech-tom.com / https://ucsystems.nl
#>
function Get-OPBearerToken {
    param (
        # API URL 
        [Alias('URI')]
        [ValidateNotNullOrEmpty()]
        [String] $URL = 'https://api.openprovider.eu/v1beta/auth/login'
    )

    begin {
        # Use TLS 1.2 for older PowerShell versions
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Check if the token already exists and is not expired
        $Token = Get-Variable -Name 'OPToken' -Scope Global -ErrorAction SilentlyContinue
    }

    process {
        if ( ($null -eq $Token) -or ($Token.CreationTime -gt $(Get-Date).AddHours(-24)) ) {
            Write-Information 'API Token is expired or does not exist. Requesting new token.'

            $Credential = Get-Credential -Message 'Enter username/password for OpenProvider API authentication:'
            
            try {
                $Body = @{
                    username = $Credential.Username
                    password = $Credential.Password | ConvertFrom-SecureString -AsPlainText
                } | ConvertTo-Json
            }
            catch {
                # AsPlainText param does not exist in PS5. Added custom function to fix.
                $Body = @{
                    username = $Credential.Username
                    password = Convert-SecureToPlain -SecureString $Credential.Password
                } | ConvertTo-Json
            }

            $Params = @{
                Method      = 'POST'
                Uri         = $URL
                Body        = $Body
                ContentType = 'application/json'
            }
                    
            try {
                $Request  = Invoke-RestMethod @Params -Verbose:$false
                $Response = ($Request).data
                
                $Data = [PSCustomObject]@{
                    Token        = $Response.Token
                    CreationTime = (Get-Date)
                }
                
                Set-Variable -Name 'OPToken' -Value $Data -Option Private -Scope 'Global'
            }
            catch {
                Write-Error $_
            }
        }
    } # end Process

    end {
        $Token = Get-Variable -Name 'OPToken' -Scope 'Global' -ErrorAction SilentlyContinue
        return $Token.Value
    }
}
