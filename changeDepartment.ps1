#Change employee's department, title and group memberships.
Start-Transcript "changeDepartment_log.txt"
function Find-User(){
    #search for employee by partial full name. Select correct account from list.
    $findUser = Read-Host "Name"
    
    $searchName = '*'+$findUser+'*'
    
    $selectedUser = Get-ADUser -Filter {Name -like $searchName} -Properties Title, Department | 
    Select-Object Name, SAMAccountName, Title, Department | Out-GridView -PassThru 
    
    if ($Null -eq $selectedUser){
        "Could not find an account with that name.`n"
        Find-User
        }
    else{get-aduser $selectedUser.SAMaccountName -Properties MemberOf -ErrorAction Ignore}
}


function Update-Memberships(){
    #Remove current group memberships
    #copy memberships from target user

    Param(
    [parameter(position=1)]
    $ChangingUser,

    [parameter(position=2)]
    $TemplateUser
    )

    #Remove current memberships. Add memberships of another user
    "Removing existing memberships"
    $ChangingUser.MemberOf | Remove-ADGroupMember -Members $ChangingUser.SamAccountName -PassThru

    "Adding new memberships"
    $TemplateUser.MemberOf | Add-ADGroupMember -Members $ChangingUser.SamAccountName -PassThru
    "`nNew group memberships:"
    (Get-ADUser $ChangingUser.SAMaccountName -Properties MemberOf).MemberOf | 
    Get-ADGroup | Select-Object -ExpandProperty Name

}

function Update-JobTitle($ChangingUser){
    #Change job title and department
    $TitlePrompt = "`nWhat is {0}'s new job title?" -f $ChangingUser.Name

    $DepartmentPrompt = "`nWhat department is {0} moving to?" -f $ChangingUser.Name

    $NewTitle = Read-Host -Prompt $TitlePrompt

    $NewDepartment = Read-Host -Prompt $DepartmentPrompt

    "Updating info for {0}." -f $ChangingUser.Name

    Set-ADUser -Identity $ChangingUser.SAMaccountName -Title $NewTitle -Description $NewTitle -Department $NewDepartment
}

########################################################

"`nName of promoted employee?"
$ChangingUser = Find-User

"`nName of person with correct permissions?"
$TemplateUser = Find-User 

Update-JobTitle $ChangingUser

Update-Memberships $ChangingUser $TemplateUser

Stop-Transcript