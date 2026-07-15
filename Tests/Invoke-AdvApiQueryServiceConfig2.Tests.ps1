
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'
    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath "..\PureInvoke" -Resolve) -Verbose:$false

    $script:scmHandle = Invoke-AdvApiOpenSCManager
    $script:svcHandle = $null
    $script:svcName = $null

    function ThenError
    {
        param(
            [Parameter(Mandatory, ParameterSetName='IsEmpty')]
            [switch] $IsEmpty,

            [Parameter(Mandatory, ParameterSetName='Matches')]
            [String] $MatchesRegex
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
}

AfterAll {
    Invoke-AdvApiCloseServiceHandle -Handle $script:scmHandle
}

Describe 'Invoke-AdvApiQueryServiceConfig2' {
    BeforeEach {
        $Global:Error.Clear()
    }

    Context 'service that is delayed auto-start, has a description, failure actions, required privileges, SID type' {
        BeforeAll {
            $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                                         -ServiceName 'BITS' `
                                                         -DesiredAccess QueryConfig
        }

        AfterAll {
            Invoke-AdvApiCloseServiceHandle -Handle $script:svcHandle
        }

        It 'reads delayed auto start' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel DelayedAutoStart
            ThenError -IsEmpty
            $info | Should -Not -BeNullOrEmpty
            $info | Should -BeOfType ([pscustomobject])
            $info.DelayedAutoStart | Should -BeTrue
        }

        It 'reads description' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Description
            ThenError -IsEmpty
            $info | should -Not -BeNullOrEmpty
            $info.Description | Should -BeLike '*transfers files*'
        }

        It 'reads failure actions' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel FailureActions
            ThenError -IsEmpty
            $info | Should -Not -BeNullOrEmpty
            $info.ResetPeriod | Should -Be 86400
            $info.RebootMessage | Should -BeNullOrEmpty
            $info.Command | should -BeNullOrEmpty
            $info.Actions | Should -HaveCount 3
            $info.Actions[0].Type | Should -Be 'Restart'
            $info.Actions[0].Delay | Should -Be 60000
            $info.Actions[1].Type | Should -Be 'Restart'
            $info.Actions[1].Delay | Should -Be 120000
            $info.Actions[2].Type | Should -Be 'None'
            $info.Actions[2].Delay | Should -Be 0
        }

        # In my testing, QueryServiceConfig2 always returns a "parameter is incorrect (87)" error when querying
        # PreferredNode.
        It 'fails to reads CPU preferred node' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle `
                                                     -InfoLevel PreferredNode `
                                                     -ErrorAction SilentlyContinue
            ThenError -Matches 'failed to determine memory needed to read PreferredNode'
            $info | Should -BeNullOrEmpty
        }

        It 'reads privileges' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel RequiredPrivileges
            $info | Should -Not -BeNullOrEmpty
            $info.RequiredPrivileges | Should -HaveCount 6
            $info.RequiredPrivileges | Should -Contain 'SeCreateGlobalPrivilege'
            $info.RequiredPrivileges | Should -Contain 'SeImpersonatePrivilege'
            $info.RequiredPrivileges | Should -Contain 'SeTcbPrivilege'
            $info.RequiredPrivileges | Should -Contain 'SeAssignPrimaryTokenPrivilege'
            $info.RequiredPrivileges | Should -Contain 'SeIncreaseQuotaPrivilege'
            $info.RequiredPrivileges | Should -Contain 'SeDebugPrivilege'
        }

        It 'reads SID type' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel SidType
            $info | Should -Not -BeNullOrEmpty
            $info.SidType | Should -Be 'Unrestricted'
        }
    }

    Context 'service that runs failure actions on non-crash failures' {
        BeforeAll {
            $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                                         -ServiceName 'EventLog' `
                                                         -DesiredAccess QueryConfig
        }

        AfterAll {
            Invoke-AdvApiCloseServiceHandle -Handle $script:svcHandle
        }

        It 'reads failure action flags' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel FailureActionsFlag
            ThenError -IsEmpty
            $info | Should -Not -BeNullOrEmpty
            $info.FailureActionsOnNonCrashFailures | Should -BeTrue
        }
    }

    Context 'service that configures preshutdown timeout' {
        BeforeAll {
            $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                                         -ServiceName 'TrustedInstaller' `
                                                         -DesiredAccess QueryConfig
        }

        AfterAll {
            Invoke-AdvApiCloseServiceHandle -Handle $script:svcHandle
        }

        It 'reads preshutdown timeout' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Preshutdown
            ThenError -IsEmpty
            $info | Should -Not -BeNullOrEmpty
            $info.PreshutdownTimeout | Should -Be 3600000
        }
    }

    Context 'service that configures multiple triggers' {
        BeforeAll {
            $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                                         -ServiceName 'ClipSVC' `
                                                         -DesiredAccess QueryConfig
        }

        AfterAll {
            Invoke-AdvApiCloseServiceHandle -Handle $script:svcHandle
        }

        It 'reads triggers' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Triggers
            ThenError -IsEmpty
            $info | Should -Not -BeNullOrEmpty
            $info.Triggers | Should -Not -BeNullOrEmpty
            $info.Reserved | Should -Be 0

            $info.Triggers[0] | Should -Not -BeNullOrEmpty
            $info.Triggers[0].Type | Should -Be 'NetworkEndpoint'
            $info.Triggers[0].Action | Should -Be 'Start'
            $info.Triggers[0].SubType | Should -Be 'bc90d167-9470-4139-a9ba-be0bbbf5b74d'
            $info.Triggers[0].DataItems | Should -HaveCount 1

            $info.Triggers[1] | Should -Not -BeNullOrEmpty
            $info.Triggers[1].Type | Should -Be 7
            $info.Triggers[1].Action | Should -Be 'Start'
            $info.Triggers[1].SubType | Should -Be '2d7a2816-0c5e-45fc-9ce7-570e5ecde9c9'
            $info.Triggers[1].DataItems | Should -HaveCount 1
            $info.Triggers[1].DataItems[0].Type | Should -Be 'Binary'
            $info.Triggers[1].DataItems[0].Data | Should -Not -BeNullOrEmpty
        }
    }

    Context 'service that configures trigger with multiple data items' {
        BeforeAll {
            $svcName = 'TextInputManagementService'
            if (-not (Get-Service -Name $svcName -ErrorAction Ignore))
            {
                $svcName = 'TabletInputService'
            }
            if (-not (Get-Service -Name $svcName -ErrorAction Ignore))
            {
                Write-Error -Message 'Failed to find a service that has multiple data items.'
                return
            }

            $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                                         -ServiceName $svcName `
                                                         -DesiredAccess QueryConfig
        }

        AfterAll {
            Invoke-AdvApiCloseServiceHandle -Handle $script:svcHandle
        }

        It 'reads data items' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Triggers
            ThenError -IsEmpty
            $info | Should -Not -BeNullOrEmpty
            $info.Triggers | Should -HaveCount 1
            $info.Reserved | Should -Be 0

            $info.Triggers[0] | Should -Not -BeNullOrEmpty
            $info.Triggers[0].Type | Should -Be 'DeviceInterfaceArrival'
            $info.Triggers[0].Action | Should -Be 'Start'
            $info.Triggers[0].SubType | Should -Be '4d1e55b2-f16f-11cf-88cb-001111000030'

            $dataItems = $info.Triggers[0].DataItems
            $dataItems | Should -HaveCount 4
            $dataItems[0].Type | Should -Be 'String'
            $dataItems[0].Data | Should -Be 'HID_DEVICE_UP:000D_U:0001'
            $dataItems[1].Type | Should -Be 'String'
            $dataItems[1].Data | Should -Be 'HID_DEVICE_UP:000D_U:0002'
            $dataItems[2].Type | Should -Be 'String'
            $dataItems[2].Data | Should -Be 'HID_DEVICE_UP:000D_U:0003'
            $dataItems[3].Type | Should -Be 'String'
            $dataItems[3].Data | Should -Be 'HID_DEVICE_UP:000D_U:0004'
        }
    }

    Context 'protected service' {
        BeforeAll {
            $script:svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                                         -ServiceName 'AppIDSvc' `
                                                         -DesiredAccess QueryConfig
        }

        AfterAll {
            Invoke-AdvApiCloseServiceHandle -Handle $script:svcHandle
        }

        It 'reads launch protection' {
            $info = Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel LaunchProtected
            ThenError -IsEmpty
            $info | Should -Not -BeNullOrEmpty
            $info.LaunchProtected | Should -Be 'WindowsLight'
        }
    }

    $svcNames = Get-Service | Select-Object -ExpandProperty 'Name'
    It 'queries <_> service' -ForEach $svcNames {
        $svcHandle = Invoke-AdvApiOpenService -SCManagerHandle $script:scmHandle `
                                              -ServiceName $_ `
                                              -DesiredAccess QueryConfig

        try
        {
            {
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel DelayedAutoStart
                # On my computer, reading the WaaSMedicSvc service's description throws an error, even in the services
                # UI. On build servers, reading the CDPUserSvc_26dec service's description throws "The resource loader
                # failed to find MUI file." exception.
                if ($_ -ne 'WaaSMedicSvc' -and $_ -notlike 'CDPUserSvc*')
                {
                    Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Description
                }
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel FailureActions
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel FailureActionsFlag
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel LaunchProtected
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Preshutdown
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel RequiredPrivileges
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel SidType
                Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $svcHandle -InfoLevel Triggers
            } | Should -Not -Throw -Because "should be able to query ${_} configuration"
            ThenError -IsEmpty
        }
        finally
        {
            Invoke-AdvApiCloseServiceHandle -Handle $svcHandle
        }
    }
}