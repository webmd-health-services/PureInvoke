
[ ] Create functions that expose APIs to allow access to service's system DACL. Update the tests for
QueryServiceObjectSecurity and SetServiceObjectSecurity to validate they work. REmove "unsupported" comments in
Invoke-AdvApiQueryServiceObjectSecurity documentation.

> The handle specified by hService must have ACCESS_SYSTEM_SECURITY access.
> To obtain ACCESS_SYSTEM_SECURITY access:
>
> * Enable the SE_SECURITY_NAME privilege in the current access token of the caller.
> * Open the handle for ACCESS_SYSTEM_SECURITY access.
> * Disable the privilege.

