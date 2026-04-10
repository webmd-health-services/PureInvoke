[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Description', 'FailureActions', 'DelayedAutoStart', 'FailureActionsFlag', 'SidType',
                 'RequiredPrivileges', 'Preshutdown', 'Triggers', 'PreferredNode', 'LaunchProtected')]
    [String] $InfoLevel,

    [String] $Name
)

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'PureInvoke' -Resolve)

$scmHandle = Invoke-AdvApiOpenSCManager

$nameArg = @{}
if ($Name)
{
    $nameArg['Name'] = $Name
}
try
{
    foreach ($svc in (Get-Service @nameArg))
    {
        WRite-Verbose "$($svc.DisplayName) ($($svc.Name))"
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $scmHandle -ServiceName $svc.Name
        Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel $InfoLevel |
            Add-Member -Name 'Name' -MemberType NoteProperty -Value $svc.Name -PassThru |
            Add-Member -Name 'DisplayName' -MemberType NoteProperty -Value $svc.DisplayName -PassThru |
            Write-Output
        Invoke-AdvApiCloseServiceHandle -Handle $svcHandle
    }
}
finally
{
    Invoke-AdvApiCloseServiceHandle -Handle $scmHandle
}