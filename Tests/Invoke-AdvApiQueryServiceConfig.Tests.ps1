
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
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                              -ServiceName 'W32Time' `
                                              -DesiredAccess QueryConfig
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
        $info.Dependencies | Sort-Object | Should -Be ($svc.ServicesDependedOn | Select-Object 'Name' | Sort-Object)
        $info.ServiceStartName | Should -Be 'NT AUTHORITY\LocalService'
        $info.DisplayName | Should -Be 'Windows Time'
    }

    $svcNames =
        Get-Service -ErrorAction Ignore |
        Select-Object -ExpandProperty 'Name' |
        Where-Object { $_ -notlike 'CDPUserSvc*' }
    It 'queries <_> service' -ForEach $svcNames {
        $svc = Get-Service -Name $_
        $svcHandle =
            Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle -ServiceName $_ -DesiredAccess QueryConfig
        try
        {
            $config = Invoke-AdvApiQueryServiceConfig -ServiceHandle $svcHandle
            ThenError -IsEmpty

            $config | Should -Not -BeNullOrEmpty
            $config.ServiceType | Should -BeOfType ([Enum])
            $config.StartType | Should -Be $svc.StartType
            $config.ErrorControl | Should -BeOfType ([Enum])
            $config.BinaryPathName | Should -BeOfType ([String])
            $config.LoadOrderGroup | Should -BeOfType ([String])
            $config.TagID | Should -Not -BeNullOrEmpty
            # Get-Service doesn't report all the RemoteAccess service's dependencies
            $null -eq $config.Dependencies | Should -BeFalse
            ,$config.Dependencies | Should -BeOfType ([String[]])
            if ($_ -ne 'RemoteAccess')
            {
                $config.Dependencies |
                    Sort-Object |
                    Should -Be ($svc.ServicesDependedOn | Select-Object -ExpandProperty 'Name' | Sort-Object)
            }
            $config.ServiceStartName | Should -BeOfType ([String])
            $config.DisplayName | Should -Be $svc.DisplayName

        }
        finally
        {
            Invoke-AdvApiCloseServiceHandle -Handle $svcHandle
        }
    }
}