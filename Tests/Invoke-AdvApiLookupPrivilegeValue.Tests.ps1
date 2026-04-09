
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
}

Describe 'Invoke-AdvApiLookupPrivilegeValue' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'fails' {
        Invoke-AdvApiLookupPrivilegeValue -Name 'fubarsnafu' -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        $Global:Error | Should -Match 'privilege does not exist'
    }

    # Does not include these rights because these are account rights not privileges. See
    # https://learn.microsoft.com/en-us/windows/win32/secauthz/account-rights-constants#remarks
    # SeBatchLogonRight
    # SeDenyBatchLogonRight
    # SeDenyInteractiveLogonRight
    # SeDenyNetworkLogonRight
    # SeDenyRemoteInteractiveLogonRight
    # SeDenyServiceLogonRight
    # SeInteractiveLogonRight
    # SeNetworkLogonRight
    # SeRemoteInteractiveLogonRight
    # SeServiceLogonRight

    # Known privileges. See https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants.
    $knownPrivileges = @(
        'SeAssignPrimaryTokenPrivilege',
        'SeAuditPrivilege',
        'SeBackupPrivilege',
        'SeChangeNotifyPrivilege',
        'SeCreateGlobalPrivilege',
        'SeCreatePagefilePrivilege',
        'SeCreatePermanentPrivilege',
        'SeCreateSymbolicLinkPrivilege',
        'SeCreateTokenPrivilege',
        'SeDebugPrivilege',
        'SeEnableDelegationPrivilege',
        'SeImpersonatePrivilege',
        'SeIncreaseBasePriorityPrivilege',
        'SeIncreaseQuotaPrivilege',
        'SeIncreaseWorkingSetPrivilege',
        'SeLoadDriverPrivilege',
        'SeLockMemoryPrivilege',
        'SeMachineAccountPrivilege',
        'SeManageVolumePrivilege',
        'SeProfileSingleProcessPrivilege',
        'SeRelabelPrivilege',
        'SeRemoteShutdownPrivilege',
        'SeRestorePrivilege',
        'SeSecurityPrivilege',
        'SeShutdownPrivilege',
        'SeSyncAgentPrivilege',
        'SeSystemEnvironmentPrivilege',
        'SeSystemProfilePrivilege',
        'SeSystemtimePrivilege',
        'SeTakeOwnershipPrivilege',
        'SeTcbPrivilege',
        'SeTimeZonePrivilege',
        'SeTrustedCredManAccessPrivilege',
        'SeUndockPrivilege'
    )
    It 'finds <_>' -TestCases $knownPrivileges {
        $result = Invoke-AdvApiLookupPrivilegeValue -Name $_
        $Global:Error | Should -BeNullOrEmpty
        $result | Should -Not -BeNullOrEmpty
        $result.LowPart | Should -Not -Be 0
        $result.LowPart | Should -BeOfType ([UInt32])
        $result.HighPart | Should -Be 0
        $result.HighPart | Should -BeOfType ([int])
    }
}