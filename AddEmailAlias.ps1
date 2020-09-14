#add an email alias to a user.

[cmdletbinding()]
PARAM(
    [parameter(Mandatory=$true)]
    [String]
    $username,
    [parameter(Mandatory=$true)]
    [String]
    $EmailAlias
)

"Current proxy addresses for $username"
(Get-aduser -Identity $username -Properties ProxyAddresses).ProxyAddresses

$SMTPaddress = "smtp:$EmailAlias"

#if no one else has the alias it's OK to add
$AliasSearch = (Get-ADUser -Filter 'ProxyAddresses -like $SMTPaddress' -Properties ProxyAddresses)
if($null -eq $AliasSearch){
    "Adding $EmailAlias to $username"
    Set-ADUser -Identity $username -Add @{ProxyAddresses=$SMTPaddress}
    "New proxy address list for $username"
    (Get-aduser -Identity $username -Properties ProxyAddresses).ProxyAddresses
}
else{
    "$EmailAlias is already in use."
    $AliasSearch
}

Read-Host -Prompt "Press Enter to exit."
