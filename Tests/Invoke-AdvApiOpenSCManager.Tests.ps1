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

    $script:handle = [IntPtr]::Zero

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
            $Global:Error | Should -Match $MatchesRegex
        }
    }

    function ThenManager
    {
        param(
            [switch] $Not,
            [switch] $Opened
        )

        if ($Not)
        {
            $script:handle | Test-PInvokeHandle | Should -BeFalse
            return
        }

        $script:handle | Test-PInvokeHandle | Should -BeTrue
        $script:handle | Should -BeOfType [IntPtr]
        # Now make sure the handle can be used.
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:handle -ServiceName 'EventLog'
        $svcHandle | Test-PInvokeHandle | Should -BeTrue
        $svcHandle | Should -BeOfType [IntPtr]
        $svcHandle | Invoke-AdvApiCloseServiceHandle
    }

    function WhenOpening
    {
        param(
            [hashtable] $WithArgs = @{}
        )

        $script:handle = Invoke-AdvApiOpenSCManager @WithArgs
    }
}

Describe 'Invoke-AdvApiOpenSCManager' {
    BeforeEach {
        $Global:Error.Clear()
        $script:handle = [IntPtr]::Zero
    }

     AfterEach {
        if ($script:handle | Test-PInvokeHandle)
        {
            $script:handle | Invoke-AdvApiCloseServiceHandle
        }
    }

    It 'opens the service control manager' {
        WhenOpening
        ThenManager -Opened
        ThenError -IsEmpty
    }

    It 'opens specific database' {
        WhenOpening -WithArgs @{ DatabaseName = 'ServicesActive' }
        ThenManager -Opened
        ThenError -IsEmpty
    }

    It 'fails to open non-existent database' {
        WhenOpening -WithArgs @{ DatabaseName = 'NonExistentDatabase' ; ErrorAction = 'SilentlyContinue' }
        ThenManager -Not -Opened
        ThenError -MatchesRegex 'database "NonExistentDatabase"'
    }

    It 'includes machine name in error message' {
        WhenOpening -WithArgs @{ MachineName = 'NonExistentMachine' ; ErrorAction = 'SilentlyContinue' }
        ThenManager -Not -Opened
        ThenError -MatchesRegex 'on computer "NonExistentMachine"'
    }

    It 'includes database name in error message' {
        WhenOpening -WithArgs @{ DatabaseName = 'NonExistentDatabase' ; ErrorAction = 'SilentlyContinue' }
        ThenManager -Not -Opened
        ThenError -MatchesRegex 'database "NonExistentDatabase"'
    }

    It 'includes access rights in error message' -Skip:$script:isAdmin {
        WhenOpening -WithArgs @{ DesiredAccess = 'CreateService' ; ErrorAction = 'SilentlyContinue' }
        ThenManager -Not -Opened
        ThenError -MatchesRegex ([regex]::Escape('with CreateService (0x2)'))
    }

    It 'opens with specific access rights' {
        # Anyone can haz read
        $access = 'Read'
        if($script:isAdmin)
        {
            $access = 'CreateService'
        }

        WhenOpening -WithArgs @{ DesiredAccess = $access }
        ThenManager -Opened
        ThenError -IsEmpty
    }
}