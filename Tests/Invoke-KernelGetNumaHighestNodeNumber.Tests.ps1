
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\PureInvoke" -Resolve) -Verbose:$false
}

Describe 'Invoke-KernelGetNumaHighestNodeNumber' {
    It 'returns a value' {
        $result = Invoke-KernelGetNumaHighestNodeNumber
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeOfType ([UInt32])
        $result | Should -Be 0
    }
}