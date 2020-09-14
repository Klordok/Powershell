#update UPN of all user in csv to match their primary SMTP address

$AddressFile = "NewPrimarySMTP_v2.csv"

While((Get-PSSession).State -ne 'Opened')#if no active session
{
    "You're not connected to Exchange yet.`n"

    Get-PSSession | Remove-PSSession #remove old sessions

    $UserCredential = Get-Credential -Message "a-account credentials"
    $exchangeConnectionURI = "http://exchange01/PowerShell/"
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $exchangeConnectionURI -Authentication Kerberos -Credential $UserCredential

    Import-PSSession $Session -AllowClobber
}
"Connected to Exchange `n"

function Update-UPN{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $FilePath
    )
    #Import names from csv. Skip original headers
    $UserList = Get-Content -Path $FilePath | Select-Object -Skip 1 | ConvertFrom-Csv -Header Name

    "Exporting list of current Names and UPNs"
    $CurrentUPNList = $UserList.Name | Get-Mailbox | Select-Object Name,PrimarySMTPAddress,UserPrincipalName
    $CurrentUPNList | Export-Csv "Old_UPN_List.csv" -NoTypeInformation
    "Export complete."

    "Setting new User Principal Name"
    ForEach($Account in $CurrentUPNList){
        #Remove -WhatIf when ready to go
        Set-Mailbox $Account.Name -UserPrincipalName $Account.PrimarySMTPAddress -WhatIf
    }

    "Update complete. Exporting new list of Names and UPNs."
    $NewUPNList = $UserList.Name | Get-Mailbox | Select-Object Name,PrimarySMTPAddress,UserPrincipalName
    $NewUPNList | Export-Csv "New_UPN_List.csv" -NoTypeInformation
    "Export complete"

}

Update-UPN -FilePath $AddressFile

#Remove exchange session
"Removing Exchange session"
Get-PSSession | Remove-PSSession