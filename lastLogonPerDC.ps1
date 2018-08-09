[cmdletbinding()]

PARAM(
    [Parameter(Mandatory=$true)]
    [string]$username
    )

#Get list of all domain controllers
$DCList = (Get-ADDomainController -Filter *).Name

$DCLogonTimes = @()
foreach($dc in $DCList){
#Find the last time the user logged on to each DC
    "Checking "+$dc 
    $dcLastLogon = Get-ADUser -Identity $username | Get-ADObject -Server $DC -Properties lastLogon |
    Select-Object @{Name='DC';Expression={$DC}}, @{Name='LastLogon';Expression={[datetime]::FromFileTime($_.lastlogon)}} -ErrorAction Stop

    $DCLogonTimes += $dcLastLogon

}
Get-aduser -Identity $username -Properties LockedOut, PasswordExpired, PasswordLastSet | Select Name, LockedOut, PasswordExpired, PasswordLastSet

#Show log on times for all DCs starting with most recent.
$DCLogonTimes | Sort-Object LastLogon -Descending | FT -AutoSize
