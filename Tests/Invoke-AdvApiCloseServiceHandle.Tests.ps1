using namespace System.Security.Principal

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\PureInvoke" -Resolve) -Verbose:$false

    $script:scmHandle = [IntPtr]::Zero

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

    function ThenHandle
    {
        param(
            [switch] $Closed
        )

        $script:scmHandle | Should -BeOfType [IntPtr]
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                              -ServiceName 'EventLog' `
                                              -Erroraction SilentlyContinue
        $Global:Error[0] | Should -Match 'handle is invalid' -Because 'should not be able to use a closed handle'
        $svcHandle | Test-PInvokeHandle | Should -BeFalse
    }

    function ThenReturned
    {
        param(
            [switch] $Nothing
        )

        $script:result | Should -BeNullOrEmpty
    }

    function WhenClosing
    {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ParameterSetName='Pipeline')]
            [IntPtr] $Handle,

            [Parameter(Mandatory, ParameterSetName='Pipeline')]
            [switch] $UsingPipeline,

            [Parameter(ParameterSetName='Args')]
            [hashtable] $WithArgs = @{}
        )

        if ($UsingPipeline)
        {
            $script:result = $Handle | Invoke-AdvApiCloseServiceHandle
        }
        else
        {
            $script:result = Invoke-AdvApiCloseServiceHandle @WithArgs
        }
    }
}

Describe 'Invoke-AdvApiCloseServiceHandle' {
    BeforeEach {
        $script:scmHandle = Invoke-AdvApiOpenSCManager
        $Global:Error.Clear()
    }

    AfterEach {
        $script:scmHandle | Invoke-AdvApiCloseServiceHandle -ErrorAction SilentlyContinue
    }

    It 'closes handle' {
        WhenClosing -WithArgs @{ Handle = $script:scmHandle }
        ThenError -IsEmpty
        ThenHandle -Closed
        ThenReturned -Nothing
    }

    It 'closes handle from pipeline' {
        WhenClosing -Handle $script:scmHandle -UsingPipeline
        ThenError -IsEmpty
        ThenHandle -Closed
        ThenReturned -Nothing
    }

}
