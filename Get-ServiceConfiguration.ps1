<#
.SYNOPSIS
Calls the Windows API's `QueryServiceConfig2` function.

.DESCRIPTION
The `Get-Service-Configuration` calls the Windows API's `QueryServiceConfig` and `QueryServiceConfig2` functions. This
is hard to do from an interactive session becuase it is a five step process: open the Service Control Manager, open the
service, query the service, close the service, then close the service control manager. Use this script to inspect the
objects and values returned by `QueryServiceConfig` or `QueryServiceConfig2`. By default, all services are returned and
the function calls `QueryServiceConfig` on each.

To return a specific service, pass its name to `$Name`. To call `QueryServiceConfig2`, pass the information you want
to the `$InfoLevel` parameter.

.EXAMPLE
.\Get-ServiceConfiguration.ps1 -Name 'W32Time' -InfoLevel Triggers

Demonstrates how to use this script to call the `QueryServiceConfig2` Windows API function. In this example, the W32Time
service's triggers configuration is returned.
#>
[CmdletBinding()]
param(
    # The information to return.
    [ValidateSet('Description', 'FailureActions', 'DelayedAutoStart', 'FailureActionsFlag', 'SidType',
                 'RequiredPrivileges', 'Preshutdown', 'Triggers', 'PreferredNode', 'LaunchProtected')]
    [String] $InfoLevel,

    # The name of the service whose information to return. Defaults to all services.
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
        $svcHandle =
            Invoke-AdvApiOpenService -SCManagerHandle $scmHandle -ServiceName $svc.Name -DesiredAccess QueryConfig
        if ($InfoLevel)
        {
            Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel $InfoLevel |
                Add-Member -Name 'Name' -MemberType NoteProperty -Value $svc.Name -PassThru |
                Add-Member -Name 'DisplayName' -MemberType NoteProperty -Value $svc.DisplayName -PassThru |
                Write-Output
        }
        else
        {
            Invoke-AdvApiQueryServiceConfig -ServiceHandle $svcHandle | Write-Output
        }

        Invoke-AdvApiCloseServiceHandle -Handle $svcHandle
    }
}
finally
{
    Invoke-AdvApiCloseServiceHandle -Handle $scmHandle
}