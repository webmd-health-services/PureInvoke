
function Invoke-AdvApiQueryServiceConfig2
{
    <#
    .SYNOPSIS
    Calls the Win32 API `QueryServiceConfig2` to retrieve parts of a service's configuration.

    .DESCRIPTION
    The `Invoke-AdvApiQueryServiceConfig2` function calls the `QueryServiceConfig2` Win32 API to retrieve parts of a
    service's configuration. Pass a handle to the service to the `ServiceHandle` parameter (use
    `Invoke-AdvApiOpenService` to get a handle to a service). Pass the information you want to the `InfoLevel`
    parameter. Valid information levels and what they return are:

    * `[DelayedAutoStart](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_delayed_auto_start_info)`
    * `[Description](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_descriptionw)`
    * `[FailureActions](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actionsw)`
    * `[FailureActionsFlag](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actions_flag)`
    * `[PreferredNode](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preferred_node_info)`
    * `[Preshutdown](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preshutdown_info)`
    * `[RequiredPrivileges](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_required_privileges_infow)`
    * `[SidType](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_sid_info)`
    * `[Triggers](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger)`
    * `[LaunchProtected](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_launch_protected_info)`

    The function converts each unmanaged Win32 structure to a `[pscustomobject]` with property names similar to the
    native structures. Property names don't have the unmanaged type prefixes (e.g. `Description` instead of
    `lpDescription`). All unmanaged types are converted to managed types.

    .EXAMPLE
    Invoke-AdvApiQueryServiceConfig2 -ServiceHandle $handle -InfoLevel Description

    Demonstrates how to call `Invoke-AdvApiQueryServiceConfig2` to get part of a service's configuration. In this
    example, the service's description is returned.
    #>
    [CmdletBinding()]
    param(
        # Handle to the service whose configuration to get. Use `Invoke-AdvApiOpenService` to open the service.
        [Parameter(Mandatory = $true)]
        [IntPtr] $ServiceHandle,

        # The configuration to retrieve. Must be one of:
        #
        # * `[DelayedAutoStart](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_delayed_auto_start_info)`
        # * `[Description](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_descriptionw)`
        # * `[FailureActions](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actionsw)`
        # * `[FailureActionsFlag](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_failure_actions_flag)`
        # * `[PreferredNode](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preferred_node_info)`
        # * `[Preshutdown](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_preshutdown_info)`
        # * `[RequiredPrivileges](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_required_privileges_infow)`
        # * `[SidType](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_sid_info)`
        # * `[Triggers](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_trigger)`
        # * `[LaunchProtected](https://learn.microsoft.com/en-us/windows/win32/api/winsvc/ns-winsvc-service_launch_protected_info)`
        [Parameter(Mandatory = $true)]
        [PureInvoke_ServiceInfoLevel] $InfoLevel
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $infoToStructNameMap = @{
        [PureInvoke_ServiceInfoLevel]::DelayedAutoStart   = 'ServiceConfigDelayedAutoStart'
        [PureInvoke_ServiceInfoLevel]::Description        = 'ServiceConfigDescription'
        [PureInvoke_ServiceInfoLevel]::FailureActions     = 'ServiceConfigFailureActions'
        [PureInvoke_ServiceInfoLevel]::FailureActionsFlag = 'ServiceConfigFailureActionsFlag'
        [PureInvoke_ServiceInfoLevel]::PreferredNode      = 'ServiceConfigPreferredNode'
        [PureInvoke_ServiceInfoLevel]::Preshutdown        = 'ServiceConfigPreshutdown'
        [PureInvoke_ServiceInfoLevel]::RequiredPrivileges = 'ServiceConfigRequiredPrivileges'
        [PureInvoke_ServiceInfoLevel]::SidType            = 'ServiceConfigSid'
        [PureInvoke_ServiceInfoLevel]::Triggers           = 'ServiceConfigTriggers'
        [PureInvoke_ServiceInfoLevel]::LaunchProtected    = 'ServiceConfigLaunchProtected'
    }

    if (-not $infoToStructNameMap.ContainsKey($InfoLevel))
    {
        $msg = 'Failed to call advapi QueryServiceConfig2 because the "InfoLevel" parameter has an unknown value ' +
               "${InfoLevel}."
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    $advApi = Get-AdvApi32

    [UInt32]$bytesNeeded = 0
    $ok = $advApi::QueryServiceConfig2($ServiceHandle, [UInt32]$InfoLevel, [IntPtr]::Zero, 0, [ref] $bytesNeeded)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $ok -and $lastError -ne [PureInvoke_ErrorCode]::InsufficientBuffer)
    {
        $msg = "Failed to determine memory needed to read ${InfoLevel} service configuration."
        Write-Win32Error -ErrorCode $lastError -Message $msg
        return
    }

    $ptrInfo = [Marshal]::AllocHGlobal($bytesNeeded)
    $ok = $advApi::QueryServiceConfig2($ServiceHandle, [UInt32]$InfoLevel, $ptrInfo, $bytesNeeded, [ref] $bytesNeeded)
    $lastError = [Marshal]::GetLastWin32Error()
    if (-not $ok)
    {
        Write-Win32Error -ErrorCode $lastError -Message "Failed to query service ${InfoLevel} configuration."
        return
    }

    $structName = $infoToStructNameMap[$InfoLevel]
    $info = $advApi | New-PInvokeStruct -Name $structName
    [Marshal]::PtrToStructure($ptrInfo, $info)

    try
    {
        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::DelayedAutoStart)
        {
            return [pscustomobject]@{
                DelayedAutoStart = $info.DelayedAutoStart
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::Description)
        {
            return [pscustomobject]@{
                Description = $info.Description
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::FailureActions)
        {
            $actions = [Collections.ArrayList]::New($info.ActionsCount)
            $offset = 0
            for ($actionIdx = 0 ; $actionIdx -lt $info.ActionsCount ; ++$actionIdx)
            {
                $action = $advApi | New-PInvokeStruct -Name 'ServiceConfigFailureAction'
                $offset = [Marshal]::SizeOf($action) * $actionIdx
                $ptrAction = [IntPtr]::Add($info.Actions, $offset)
                [Marshal]::PtrToStructure($ptrAction, $action)

                $actionType = $action.Type
                if ($script:actionTypes.Contains($actionType))
                {
                    $actionType = [PureInvoke_ServiceActionType]$actionType
                }

                [void]$actions.Add(
                    [pscustomobject]@{
                        Type = $actionType
                        Delay = $action.Delay
                    }
                )
            }

            return [pscustomobject]@{
                ResetPeriod = $info.ResetPeriod
                RebootMessage = $info.RebootMsg
                Command = $info.Command
                Actions = $actions.ToArray()
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::FailureActionsFlag)
        {
            return [pscustomobject]@{
                FailureActionsOnNonCrashFailures = $info.FailureActionsOnNonCrashFailures
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::PreferredNode)
        {
            return [pscustomobject]@{
                PreferredNode = $info.PreferredNode
                Delete = $info.Delete
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::Preshutdown)
        {
            return [pscustomobject]@{
                PreshutdownTimeout = $info.PreshutdownTimeout
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::RequiredPrivileges)
        {
            [String[]]$privs = ConvertFrom-MultiString -Handle $info.RequiredPrivileges

            return [pscustomobject]@{
                RequiredPrivileges = $privs
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::SidType)
        {
            return [pscustomobject]@{
                SidType = [PureInvoke_ServiceSidType]$info.SidType
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::Triggers)
        {
            $triggers = [Collections.ArrayList]::New($info.TriggersCount)
            for ($triggerIdx = 0 ; $triggerIdx -lt $info.TriggersCount ; ++$triggerIdx)
            {
                $trigger = $advApi | New-PInvokeStruct -Name 'ServiceConfigTrigger'
                $sizeOfTrigger = [Marshal]::SizeOf($trigger)
                [IntPtr]$ptrTrigger = [IntPtr]::Add($info.Triggers, ($sizeOfTrigger * $triggerIdx))
                [Marshal]::PtrToStructure($ptrTrigger, $trigger)

                # There are some undocumented values: 7 and 30.
                $triggerType = $trigger.Type
                if ($script:triggerTypes.Contains($triggerType))
                {
                    $triggerType = [PureInvoke_ServiceTriggerType]$triggerType
                }

                $subtype = [Marshal]::PtrToStructure($trigger.Subtype, ([Type][Guid]))

                $dataItems = [Collections.ArrayList]::New($trigger.DataItemsCount)
                for ($dataItemIdx = 0 ; $dataItemIdx -lt $trigger.DataItemsCount ; ++$dataItemIdx)
                {
                    $dataItem = $advApi | New-PInvokeStruct -Name 'ServiceConfigTriggerSpecificDataItem'
                    $offset = [Marshal]::SizeOf($dataItem) * $dataItemIdx
                    $ptrDataItem = [IntPtr]::Add($trigger.DataItems, $offset)
                    [Marshal]::PtrToStructure($ptrDataItem, $dataItem)

                    $dataSize = $dataItem.Size
                    $dataType = [PureInvoke_ServiceTriggerDataType]$dataItem.Type
                    $data = $null

                    if ($dataType -eq [PureInvoke_ServiceTriggerDataType]::String)
                    {
                        $data = ConvertFrom-MultiString -Handle $dataItem.Data
                        if ($triggerType -eq [PureInvoke_ServiceTriggerType]::FirewallPortEvent)
                        {
                            $data = [String[]](ConvertFrom-MultiString -Handle $dataItem.Data)
                        }
                        else
                        {
                            # For some reason, PtrToStringUni without a length copies way past the end of the string.
                            $data = [Marshal]::PtrToStringUni($dataItem.Data, (($dataSize - 2) / 2))
                        }
                    }
                    elseif ($dataType -eq [PureInvoke_ServiceTriggerDataType]::KeywordAny -bor `
                            $dataType -eq [PureInvoke_ServiceTriggerDataType]::KeywordAll)
                    {
                        $data = [Marshal]::ReadInt64($dataItem.Data)
                        $data = [BitConverter]::ToUInt64([BitConverter]::GetBytes($data), 0)
                    }
                    elseif ($dataType -eq [PureInvoke_ServiceTriggerDataType]::Level)
                    {
                        $data = [Marshal]::ReadByte()
                    }
                    else
                    {
                        $data = [byte[]]::New($dataSize)
                        [Marshal]::Copy($dataItem.Data, $data, 0, $dataSize)
                    }

                    [void]$dataItems.Add(
                        [pscustomobject]@{
                            Type = $dataType
                            Data = $data
                        }
                    )
                }

                [void]$triggers.Add(
                    [pscustomobject]@{
                        Type = $triggerType
                        Action = [PureInvoke_ServiceTriggerAction]$trigger.Action
                        Subtype = $subtype
                        DataItems = $dataItems.ToArray()
                    }
                )
            }

            return [pscustomobject]@{
                Triggers = $triggers.ToArray()
                Reserved = $info.Reserved
            }
        }

        if ($InfoLevel -eq [PureInvoke_ServiceInfoLevel]::LaunchProtected)
        {
            return [pscustomobject]@{
                LaunchProtected = [PureInvoke_ServiceProtectionType]$info.LaunchProtected
            }
        }
    }
    finally
    {
        [Marshal]::FreeHGlobal($ptrInfo)
    }
}