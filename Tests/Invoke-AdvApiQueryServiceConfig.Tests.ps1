
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\PureInvoke" -Resolve) -Verbose:$false

    $script:scmHandle = Invoke-AdvApiOpenSCManager

    function ThenError
    {
        param(
            [Parameter(Mandatory, ParameterSetName='IsEmpty')]
            [switch] $IsEmpty
        )

        if ($IsEmpty)
        {
            $Global:Error | Should -BeNullOrEmpty
        }
    }
}

AfterAll {
    Invoke-AdvApiCloseServiceHandle -Handle $script:scmHandle
}

Describe 'Invoke-AdvApiQueryServiceConfig' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'reads service config' {
        $svc = Get-Service -Name 'W32Time'
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle -ServiceName 'W32Time'
        $info = $null
        try
        {
            $info = Invoke-AdvApiQueryServiceConfig -ServiceHandle $svcHandle
        }
        finally
        {
            Invoke-AdvApiCloseServiceHandle -Handle $svcHandle
        }

        $info | Should -Not -BeNullOrEmpty
        $info | Should -BeOfType ([pscustomobject])
        $info.ServiceType | Should -Be ([ServiceProcess.ServiceType]::Win32ShareProcess)
        $info.StartType | Should -Be $svc.StartType
        $info.ErrorControl | Should -Be 1
        $info.BinaryPathName | Should -Be 'C:\Windows\system32\svchost.exe -k LocalService'
        $info.LoadOrderGroup | Should -Be ''
        $info.TagID | Should -Be 0
        $info.ServiceStartName | Should -Be 'NT AUTHORITY\LocalService'
        $info.DisplayName | Should -Be 'Windows Time'
    }

    $svcNames = Get-Service | Select-Object -ExpandProperty 'Name'
    It 'queries <_> service' -ForEach $svcNames {
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle -ServiceName $_
        try
        {
            { Invoke-AdvApiQueryServiceConfig -ServiceHandle $svcHandle } | Should -Not -Throw
            ThenError -IsEmpty
        }
        finally
        {
            Invoke-AdvApiCloseServiceHandle -Handle $svcHandle
        }
    }
}