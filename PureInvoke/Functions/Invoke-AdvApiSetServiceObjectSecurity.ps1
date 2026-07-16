
function Invoke-AdvApiSetServiceObjectSecurity
{
    <#
    .SYNOPSIS
    Calls the Win32 advapi32.dll `SetServiceObjectSecurity` method.

    .DESCRIPTION
    The `Invoke-AdvApiSetServiceObjectSecurity` function call the Win32 advapi32.dll `SetServiceObjectSecurity` method.
    Pass the handle to the service whose security to set to the `ServiceHandle` parameter (use
    `Invoke-AdvApiOpenService` to open and get a handle to the service). Pass the security information to set to the
    `SecurityInformation` parameter. Pass the security descriptor to the `SecurityDescriptor` parameter. The function
    converts the security descriptor to an array of bytes and calls `SetServiceObjectSecurity`.

    Use `Invoke-AdvApiQueryServiceObjectSecurity` to get the current service's security descriptor, which you can modify
    and then pass to `Invoke-AdvApiSetServiceObjectSecurity`. Use `[Security.AccessControl.CommonAce]` to define access
    control entries for the service. [Service Security and Access
    Rights](https://learn.microsoft.com/en-us/windows/win32/services/service-security-and-access-rights) documents
    service access rights.

    When calling `Invoke-AdvApiOpenService`, make sure to request access to write the DACL and/or owner, e.g.
    `Invoke-AdvApiOpenService -DesiredAccess 'Write'` (or `WriteDac` or `WriteOwner`).

    .EXAMPLE
    Invoke-AdvApiSetServiceObjectSecurity -ServiceHandle $handle -SecurityInformation 'DiscretionaryAcl' -SecurityDescriptor $sd

    Demonstrates how to set a service's security descriptor. In this example, the service's discretionary ACL is set
    using the discretionary ACL on the `$sd` object. The rest of the security descriptor is unchanged.

    .EXAMPLE
    Invoke-AdvApiSetServiceObjectSecurity -ServiceHandle $handle -SecurityInformation 'DiscretionaryAcl, Owner' -SecurityDescriptor $sd

    Demonstrates how to set multiple parts of a service's security descriptor by passing an enum string to the
    `SecurityInformation` parameter. In this example, the service's owner and discretionary ACL are set using the
    discretionary ACL and owner on the `$sd` object. The rest of the security descriptor is unchanged.
    #>
    [CmdletBinding()]
    param(
        # Handle to the service whose security descriptor to set. Use `Invoke-AdvApiOpenService` to open and get a
        # handle to the service. Make sure write access is requested when opening the service.
        [Parameter(Mandatory)]
        [IntPtr] $ServiceHandle,

        # The parts of the security descriptor to set:
        #
        # * `Owner`
        # * `Group`
        # * `DiscretionaryAcl`
        # * `SystemAcl
        [Parameter(Mandatory)]
        [SecurityInfos] $SecurityInformation,

        # The security descriptor. Use `Invoke-AdvApiQueryServiceObjectSecurity` to get the service's current security
        # descriptor. Use `[Security.AccessControl.RawSecurityDescriptor]` to create a new security descriptor from
        # scratch.
        [Parameter(Mandatory)]
        [GenericSecurityDescriptor] $SecurityDescriptor
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $advApi = Get-AdvApi32

    [byte[]] $sdBytes = [byte[]]::New($SecurityDescriptor.BinaryLength)
    $SecurityDescriptor.GetBinaryForm($sdBytes, 0)

    $ok = $advApi::SetServiceObjectSecurity($ServiceHandle, $SecurityInformation, $sdBytes)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $ok)
    {
        Write-Win32Error -ErrorCode $lastError -Message 'Failed to set service security.'
    }
}