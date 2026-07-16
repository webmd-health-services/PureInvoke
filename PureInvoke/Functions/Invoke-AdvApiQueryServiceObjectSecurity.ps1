
function Invoke-AdvApiQueryServiceObjectSecurity
{
    <#
    .SYNOPSIS
    Calls the Win32 advapi `QueryServiceObjectSecurity` method.

    .DESCRIPTION
    The `Invoke-AdvApiQueryServiceObjectSecurity` function calls the Win32 advapi `QueryServiceObjectSecurity`, which
    returns a Windows service's security desriptor. Pass a handle to the service whose security information to get to
    the `ServiceHandle` parameter (use `Invoke-AdvApiOpenService` to get a handle to a service) and the security
    information to return to the `SecurityInformation` parameter. To request multiple security information, use and enum
    string (e.g., `Group, DiscretionaryAc`) or use `-bor` to combine `[Security.AccessControl.SecurityInfos]` together.

    Returns a `[Security.AccessControl.RawSecurityDescriptor]` with requested information filled in.

    Note that requesting the system ACL requires elevating the curent access token, which PureInvoke does not yet
    support.

    .EXAMPLE
    Invoke-AdvApiQueryServiceObjectSecurity -ServiceHandle $handle -SecurityInformation DiscretionaryAcl

    Demonstrates how to get part of a service's security. In this example, returns a
    `[Security.AccessControl.RawSecurityDescriptor]` with just the `DiscretionaryAcl` property having a value.

    .EXAMPLE
    Invoke-AdvApiQueryServiceObjectSecurity -ServiceHandle $handle -SecurityInformation 'DiscretionaryAcl, Owner'

    Demonstrates how to get multiple parts of a service's security by passing a string with multiple security
    information values to the `SecurityInformation parameter.
    #>
    [CmdletBinding()]
    [OutputType([Security.AccessControl.RawSecurityDescriptor])]
    param(
        # Handle to the service whose security information to retrieve. Use `Invoke-AdvApiOpenService` to open and get
        # the handle to a service.
        [Parameter(Mandatory)]
        [IntPtr] $ServiceHandle,

        # The security information to get. Valid values are:
        #
        # * Owner: the owner
        # * Group: the group
        # * DiscretionaryAcl: the discretionary ACL
        # * SystemAcl: the system ACL
        #
        # Note that requesting the system ACL requires elevating the curent access token, which PureInvoke does not yet
        # support.
        #
        # Multiple values can be combined using an enum string, e.g. `Owner, Group` or with `-bor`, e.g.
        # `[SecurityInfos]::Owner -bor [SecurityInfos]::Group`.
        [Parameter(Mandatory)]
        [SecurityInfos] $SecurityInformation
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $advApi = Get-AdvApi32

    [UInt32] $bytesNeeded = 0
    [byte[]] $sdBytes = [byte[]]::New(0)
    $ok = $advApi::QueryServiceObjectSecurity($ServiceHandle, $SecurityInformation, $sdBytes, 0, [ref] $bytesNeeded)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $ok -and $lastError -ne [PureInvoke_ErrorCode]::InsufficientBuffer)
    {
        $msg = 'Failed to determine memory needed to query service security descriptor.'
        Write-Win32Error -ErrorCode $lastError -Message $msg
        return
    }

    $sdBytes = [byte[]]::New($bytesNeeded)
    $ok = $advApi::QueryServiceObjectSecurity($ServiceHandle, `
                                              $SecurityInformation, `
                                              $sdBytes, `
                                              $sdBytes.Length, `
                                              [ref] $bytesNeeded)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $ok)
    {
        Write-Win32Error -ErrorCode $lastError -Message 'Failed to query service security descriptor.'
        return
    }

    return [RawSecurityDescriptor]::New($sdBytes, 0)
}
