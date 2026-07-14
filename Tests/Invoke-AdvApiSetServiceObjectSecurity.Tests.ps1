
using namespace System.Security.AccessControl
using namespace System.Security.Principal

#Requires -Version 5.1
#Requires -RunAsAdministrator
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PureInvoke' -Resolve) -Verbose:$false
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Carbon' -Resolve) `
                  -Function @('Install-CService', 'Install-CUser', 'Uninstall-CService') `
                  -Verbose:$false
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\PSModules\Carbon.Accounts' -Resolve) `
                  -Function @('Install-CLocalGroup', 'Resolve-CPrincipal') `
                  -Verbose:$false

    $password = ConvertTo-SecureString -String '.ajE0_QpJ512' -Force -AsPlainText
    $username = 'PInvSetSvcSecU'
    $svcUserCred = [pscredential]::New($username, $password)
    $description = 'User for testing PureInvoke PowerShell module''s Invoke-AdvApiSetServiceObjectSecurity function.'
    Install-CUser -Credential $svcUserCred -Description $description
    $script:svcOwnerSid = (Resolve-CPrincipal -Name $username).Sid

    $script:svcGroupSid = $null
    if ((Get-Command -Name 'Get-LocalGroup' -ErrorAction Ignore))
    {
        $groupName = 'PInvSetSvcSecG'
        $groupDesc = 'PureInvoke\Invoke-AdvApiSetServiceObjectSecurity'
        Install-CLocalGroup -Name $groupName -Description $groupDesc
        $script:svcGroupSid = (Resolve-CPrincipal -Name $groupName).Sid
    }

    $script:svcName = 'PInvSetSvcObjSec'
    $svcDisplayName = 'PureInvoke Invoke-AdvApiSetServiceObjectSecurity Test Service'
    $svcPath = Join-Path -Path $PSScriptRoot -ChildPath 'NoOpService.exe' -Resolve
    $svcDesc = 'Service for testing PureInvoke PowerShell module''s Invoke-AdvApiSetServiceObjectSecurity function.'
    Install-CService -Name $script:svcName `
                     -StartupType Disabled `
                     -Path $svcPath `
                     -Description $svcDesc `
                     -DisplayName $svcDisplayName

    $script:scmHandle = Invoke-AdvApiOpenSCManager
    $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                                 -ServiceName $script:svcName `
                                                 -DesiredAccess AllAccess

    function ThenError
    {
        param(
            [Parameter(Mandatory, ParameterSetName='Matches')]
            [String] $MatchesRegex,

            [Parameter(Mandatory, ParameterSetName='IsEmpty')]
            [switch] $IsEmpty
        )

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
        }

        if ($MatchesRegex)
        {
            $Global:Error | Should -Match $MatchesRegex
        }
    }

    function ThenServiceSecurity
    {
        param(
            [SecurityIdentifier] $HasOwner,

            [SecurityIdentifier] $HasGroup,

            [RawAcl] $HasDacl
        )

        $sd = Invoke-AdvApiQueryServiceObjectSecurity -ServiceHandle $script:svcHandle `
                                                      -SecurityInformation 'Owner, Group, DiscretionaryAcl'
        if (-not $HasOwner)
        {
            $HasOwner = $script:currentSD.Owner
        }
        $sd.Owner | Should -Be $HasOwner

        if (-not $HasGroup)
        {
            $HasGroup = $script:currentSD.Group
        }
        $sd.Group | Should -Be $HasGroup

        if (-not $HasDacl)
        {
            $HasDacl = $script:currentSD.DiscretionaryAcl
        }

        $idx = 0
        $sd.DiscretionaryAcl | Should -HaveCount ($HasDacl | Measure-Object).Count
        foreach ($expectedAce in $HasDacl)
        {
            $sd.DiscretionaryAcl[$idx++] | Should -Be $expectedAce
        }
    }

    function WhenSettingObjectSecurity
    {
        param(
            [Parameter(Mandatory)]
            [hashtable] $WithArgs
        )

        Invoke-AdvApiSetServiceObjectSecurity -ServiceHandle $script:svcHandle @WithArgs
    }
}

AfterAll {
    $script:svcHandle,$script:scmHandle | Invoke-AdvApiCloseServiceHandle

    # Uninstall so security info that get set during tests gets reset.
    Uninstall-CService -Name $script:svcName
}

Describe 'Invoke-AdvApiSetServiceObjectSecurity' {
    BeforeEach {
        $Global:Error.Clear()
        $script:currentSD =
            Invoke-AdvApiQueryServiceObjectSecurity -ServiceHandle $script:svcHandle `
                                                    -SecurityInformation 'Owner, Group, DiscretionaryAcl'

        $newDacl = [RawAcl]::New([RawAcl]::AclRevision, 1)
        $fullControl = 0xf01ff # Full Control
        $everyone = Resolve-CPrincipal -Name 'Everyone'
        $opaque = [byte[]]::New(0)
        $allow = [AceQualifier]::AccessAllowed
        $newAce = [CommonAce]::New([AceFlags]::None, $allow, $fullControl, $everyone.Sid, $false, $opaque)
        $newDacl.InsertAce(0, $newAce)
        # Fill all parts of the security descriptor so we test that only the parts given by the SecurityInformation
        # parameter are set.
        $script:newSD = [RawSecurityDescriptor]::New($script:currentSD.ControlFlags,
                                                     $script:svcOwnerSid,
                                                     $script:svcGroupSid,
                                                     $null,
                                                     $newDacl)
    }

    It 'sets the service''s owner' {
        WhenSettingObjectSecurity -WithArgs @{
            SecurityInformation = 'Owner'
            SecurityDescriptor = $script:newSD
            ErrorAction = 'SilentlyContinue'
        }
        ThenError -Matches 'security ID may not be assigned as the owner'
        ThenServiceSecurity -HasOwner $script:currentSD.Owner
    }

    $groupNotExists = -not (Get-Command -Name 'Get-LocalGroup' -ErrorAction Ignore)
    It 'sets the service''s group' -Skip:$groupNotExists {
        WhenSettingObjectSecurity -WithArgs @{ SecurityInformation = 'Group' ; SecurityDescriptor = $script:newSD }
        ThenError -IsEmpty
        ThenServiceSecurity -HasGroup $script:svcGroupSid
    }

    It 'sets the service''s dacl' {
        WhenSettingObjectSecurity -WithArgs @{
            SecurityInformation = 'DiscretionaryAcl'
            SecurityDescriptor = $script:newSD
        }
        ThenError -IsEmpty
        ThenServiceSecurity -HasDacl $script:newSD.DiscretionaryAcl
    }

    It 'sets multiple parts of the security descriptor' -Skip:$groupNotExists {
        WhenSettingObjectSecurity -WithArgs @{
            SecurityInformation = 'DiscretionaryAcl, Group'
            SecurityDescriptor = $script:newSD
        }
        ThenError -IsEmpty
        ThenServiceSecurity -HasGroup $script:newSD.Group -HasDacl $script:newSD.DiscretionaryAcl
    }
}
