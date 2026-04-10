
Migrate these from Carbon:

[ ] [Carbon.Service.ServiceSecurity]::GetServiceSecurityDescriptor($Name)
    [ ] advapi32: QueryServiceObjectSecurity
[x] [Carbon.Service.ServiceInfo]
    [x] advapi: OpenSCManager
    [x] advapi: CloseServiceHandle
    [x] advapi: OpenService
    [x] advapi: QueryServiceConfig2
    [x] advapi: QueryServiceConfig
[ ] [Carbon.Security.ServiceAccessRule]
[ ] [Carbon.Security.ServiceAccessRights]
[x] [Carbon.Service.FailureAction]
[ ] [Carbon.Service.ServiceSecurity]::SetServiceSecurityDescriptor
    [ ] advapi: SetServiceObjectSecurity
