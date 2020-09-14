#remove all print jobs in error

[cmdletbinding()]
PARAM([Parameter(Mandatory=$true)]$PrintServer)

#find all print jobs with an error status
$JobErrors = Get-Printer -computername $PrintServer | Get-PrintJob | 
Where-Object{$_.JobStatus -like "*error*" -or $_.JobStatus -like "*deleting*"} | Get-Unique

If ($null -ne $JobErrors){
    "Print Jobs with Errors:"
    $JobErrors | 
    Select-Object PrinterName, DocumentName, UserName, ToTalPages, SubmittedTime, JobStatus | Format-Table -AutoSize

    #For each printer with job errors remove all print jobs
    $JobErrors | ForEach-Object{Get-PrintJob -ComputerName $PrintServer -PrinterName $_.PrinterName} | Remove-PrintJob
    "Removed Jobs"

    Get-Service -ComputerName $PrintServer -Name Spooler | Stop-Service -Verbose
    Get-Service -ComputerName $PrintServer -Name Spooler | Start-Service -Verbose
    "Restarted Spooler service"
}

Else{"No job errors found"}