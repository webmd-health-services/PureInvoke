using namespace System.Security.Principal

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeDiscovery {
    $script:isAdmin =
        [WindowsPrincipal]::New([WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole]::Administrator)
}

BeforeAll {
    Set-StrictMode -Version 'Latest'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\PureInvoke" -Resolve) -Verbose:$false

    $script:isAdmin =
         [WindowsPrincipal]::New([WindowsIdentity]::GetCurrent()).IsInRole([WindowsBuiltInRole]::Administrator)

    $script:scmHandle = Invoke-AdvApiOpenSCManager
    $script:svcHandle = [IntPtr]::Zero

    function ThenError
    {
        param(
            [switch] $IsEmpty,

            [String] $MatchesRegex
        )

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
        }

        if ($MatchesRegex)
        {
            $Global:Error | Should -Not -BeNullOrEmpty
            $Global:Error[0] | Should -Match $MatchesRegex
        }
    }

    function ThenService
    {
        param(
            [switch] $Not,
            [switch] $Opened
        )

        if ($Not)
        {
            $script:svcHandle | Test-PInvokeHandle | Should -BeFalse
            return
        }

        $script:svcHandle | Test-PInvokeHandle | Should -BeTrue
        $script:svcHandle | Should -BeOfType [IntPtr]
    }

    function WhenOpening
    {
        param(
            [hashtable] $WithArgs = @{}
        )

        $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle @WithArgs
    }
}

Describe 'Invoke-AdvApiOpenService' {
    BeforeEach {
        $script:svcHandle = [IntPtr]::Zero
        $Global:Error.Clear()
    }

    AfterEach {
        if ($script:svcHandle | Test-PInvokeHandle)
        {
            $script:svcHandle | Invoke-AdvApiCloseServiceHandle
        }
    }

    It 'opens a service' {
        WhenOpening -WithArgs @{ ServiceName = 'EventLog' }
        ThenError -IsEmpty
        ThenService -Opened
    }

    Context 'requesting Write access' {
        Context 'adminstator' -Skip:(-not $script:isAdmin) {
            It 'opens the service' {
                WhenOpening -WithArgs @{ ServiceName = 'W32Time' ; DesiredAccess = 'Write' }
                ThenError -IsEmpty
                ThenService -Opened
            }
        }
        Context 'non-adminstrator' -Skip:$script:isAdmin {
            It 'fails' {
                $openArgs = @{ ServiceName = 'EventLog' ; DesiredAccess = 'Write' ; ErrorAction = 'SilentlyContinue' }
                WhenOpening -WithArgs $openArgs
                ThenError -Matches 'Access is denied'
                ThenError -Matches '0x80004005/5'
                ThenError -Matches 'Write \(0x20002\)'
                ThenService -Not -Opened
            }
        }
    }

    It 'accepts service from pipeline' {
        $count = 0
        Get-Service |
            Select-Object -First 3 |
            Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle |
            ForEach-Object {
                $count++
                $_ | Should -Not -Be ([IntPtr]::Zero)
                $_ | Should -Not -BeNullOrEmpty
                $_ | Should -BeOfType [IntPtr]
                $_ | Write-Output
            } |
            Invoke-AdvApiCloseServiceHandle
        ThenError -IsEmpty
    }

    It 'fails to open non-existent service' {
        WhenOpening -WithArgs @{ ServiceName = 'NonExistentService' ; ErrorAction = 'SilentlyContinue' }
        ThenError -Matches 'Failed to open service NonExistentService'
        ThenService -Not -Opened
    }
}
