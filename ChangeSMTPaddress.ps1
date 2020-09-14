#1.	Script to update all users primary SMTP address to @contoso.fabrikam.com (with the exception of ACME employees)
#Read names and Primary SMTP data from csv file. Update everyone's primary SMTP address to @contoso.fabrikam.com

$AddressFile = "AZ-NewPrimarySMTP_v2.csv"

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

function Update-PrimarySMTP{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$true)]
        $FilePath
    )
    #Import data from csv. Import first 2 columns and skip original headers
    $UserList = Get-Content -Path $FilePath | Select-Object -Skip 1 | ConvertFrom-Csv -Header Name, PrimarySMTP -ErrorAction Stop
    
    "Exporting list of current Names and Primary SMTP Addresses"
    $CurrentSMTP = $UserList.Name | Get-Mailbox | Select-Object Name,PrimarySMTPAddress
    $CurrentSMTP | Export-Csv "Old_SMTP_List.csv" -NoTypeInformation
    "Export complete."

    "Setting new Primary SMTP Address"
    ForEach($User in $UserList){
        #Remove -WhatIf when ready to go
        #Add -EmailAddressPolicyEnabled $false to bypass policy
        Set-Mailbox $User.Name -PrimarySmtpAddress $User.PrimarySMTP -WhatIf
    }

    "Update complete. Exporting new list of Names and Primary SMTP Addresses."
    $CurrentSMTP = $UserList.Name | Get-Mailbox | Select-Object Name,PrimarySMTPAddress
    $CurrentSMTP | Export-Csv "New_SMTP_List.csv" -NoTypeInformation
    "Export complete"

    #$UserList
}

Update-PrimarySMTP -FilePath $AddressFile

#Remove exchange session
"Removing Exchange session"
Get-PSSession | Remove-PSSession