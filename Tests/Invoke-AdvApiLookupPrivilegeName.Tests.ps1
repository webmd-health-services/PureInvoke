
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-Test.ps1' -Resolve)
}

Describe 'Invoke-AdvApiLookupPrivilegeName' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'fails' {
        Invoke-AdvApiLookupPrivilegeName -LuidLowPart 0 -LuidHighPart 0 -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
        $Global:Error | Should -Match 'specified privilege does not exist'
    }

    # In testing, these are the privilege values.
    $privilegeValues = 2..35
    It 'finds privilege <_>' -TestCases $privilegeValues {
        $result = Invoke-AdvApiLookupPrivilegeName -LuidLowPart $_ -LuidHighPart 0
        $Global:Error | Should -BeNullOrEmpty
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Match '^Se.*Privilege$'
    }
}