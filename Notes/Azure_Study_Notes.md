# 📚 Azure Red Team Study Notes

---

## 🎯 Quick Study Guide

### Key Concepts

### The Big 3 Components

| Component | Purpose | Key Function |
|-----------|---------|--------------|
| **Azure  Entra ID** | Identity & Access | Who can access what |
| **Azure Resource Manager (ARM)** | Infrastructure Management | How resources are organized |
| **Office 365 (O365)** | Productivity Suite | Apps and collaboration |

### 💡 Remember This:
> **Entra ID** = Identity Management  
> **ARM** = Resource Management  
> **O365** = Application Suite

---

## Azure Entra ID 

### 🎯 What is Azure Entra ID ?
- Microsoft's cloud-based identity service
- Helps employees sign in to cloud and on-premise resources
- Backbone of Office 365 system
- Can sync with on-premise Active Directory via Azure AD Connect

###  Entra ID Objects 

```
👤 Users     - Individual accounts
👥 Groups    - Collections of users  
📱 Devices   - Registered hardware
📱 Apps      - Applications & services
```

**Important:** Each object has a unique **Object ID**

### Directory Roles

**Built-in Roles:**
- **Global Administrator** - Full access to everything
- **Application Administrator** - Manages apps
- **User Administrator** - Manages users

**Custom Roles:** You can create your own!

### 🌐 Microsoft Graph API Endpoints:
```
# Current stable version
https://graph.microsoft.com/v1.0/{resource}

# Beta version (latest features)
https://graph.microsoft.com/beta/{resource}

# Example: Get all users
https://graph.microsoft.com/v1.0/users
```

---

## Azure Resource Manager (ARM)

### 🎯 What is ARM?
- Native platform for Infrastructure as Code (IaC)
- Centralizes management, deployment, and security
- Provides IaaS, PaaS, and SaaS

### Resource Hierarchy (Top to Bottom)
```
🏢 Management Group
  └── 💳 Subscription
      └── 📁 Resource Group
          └── 🖥️ Resource
```

### 🔒 RBAC (Role-Based Access Control)

**The RBAC Formula:**
```
Security Principal + Role Definition + Scope = Role Assignment
```

**Security Principals (Who?):**
- 👤 Users
- 👥 Groups  
-  Service Principals
-  Managed Identities

**Built-in ARM Roles:**
- **Owner** - Full access + can assign permissions
- **Contributor** - Full access but can't assign permissions
- **Reader** - Read-only access

### 🌐 Azure Resource Manager API:
```
# ARM REST API format
https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{resourceProviderNamespace}/{resourceType}/{resourceName}?api-version={api-version}

# Example: Get VM info
https://management.azure.com/subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.Compute/virtualMachines/{vm-name}?api-version=2023-03-01
```

---

## Office 365 Integration

### 🎯 What is Microsoft 365?
- **Now called "Microsoft 365"** (rebranded from Office 365)
- Cloud-based productivity and security suite
- Includes Office apps + security + device management
- Subscription tiers: Personal, Business, Enterprise

###  Key Applications:
- **Exchange Online** - Email
- **SharePoint Online** - Collaboration
- **OneDrive** - File storage
- **Teams** - Communication
- **Intune** - Device management

### Important URLs:
```
# Microsoft 365 Admin Centers
M365 Admin:      https://admin.microsoft.com
Entra Admin:     https://entra.microsoft.com
Azure Portal:    https://portal.azure.com
Intune Admin:    https://endpoint.microsoft.com
Security Center: https://security.microsoft.com
Compliance:      https://compliance.microsoft.com

# User Portals
M365 Apps:       https://office.com
Teams:           https://teams.microsoft.com
Outlook:         https://outlook.office.com
```

---

## Authentication Methods

### 🔐 Modern Authentication Types

| Method | Use Case | Duration | Security |
|--------|----------|----------|----------|
| **Username + Password + MFA** | Interactive login | Session | High |
| **Service Principal + Certificate** | Automated access | Long-term | High |
| **Service Principal + Secret** | Automated access | Max 2 years | Medium |
| **Managed Identity** | Azure resources | Automatic | Highest |
| **Access Token** | API calls | 1 hour | Short-term |
| **Refresh Token** | Token renewal | 90 days | Medium |
| **Device Code Flow** | Headless devices | Session | Medium |

### CLI Authentication

**Azure CLI :**
```bash
# Basic login
az login

# Service Principal
az login --service-principal -u <AppID> -p <Password> --tenant <TenantID>
```

**Azure PowerShell:**
```powershell
# Basic login
Connect-AzAccount

# Service Principal (need to create credential object first)
$cred = Get-Credential  # Username = AppID, Password = Secret
Connect-AzAccount -ServicePrincipal -Tenant <TenantID> -Credential $cred

# Access Token
Connect-AzAccount -AccessToken <Token> -AccountId <AccountID>
```

**Microsoft Graph PowerShell:**
```powershell
# Interactive login with specific scopes
Connect-MgGraph -Scopes "Directory.Read.All","User.Read.All"

# Using app-only authentication (service principal)
Connect-MgGraph -ClientId <AppId> -TenantId <TenantId> -CertificateThumbprint <Thumbprint>

# Using client secret (less secure)
Connect-MgGraph -ClientId <AppId> -TenantId <TenantId> -ClientSecret <SecureString>
```

---

## Enumeration Commands

### 🔍 Entra ID Enumeration

**Check if organization uses Entra ID:**
```
# Legacy endpoint (still works)
https://login.microsoftonline.com/getuserrealm.srf?login=user@domain.com&xml=1

# Modern endpoint
https://login.microsoftonline.com/common/userrealm/user@domain.com?api-version=2.1
```

**Response Types:**
- **Managed** - Cloud-only identities
- **Federated** - On-premises AD FS
- **Unknown** - Domain not registered

**PowerShell Commands:**
```powershell
# Get current session
Get-MgContext

# List users
Get-MgUser -All

# List groups
Get-MgGroup -All

# List directory roles
Get-MgDirectoryRole | ConvertTo-Json

# Get role members
Get-MgDirectoryRoleMember -DirectoryRoleId <ID> -All | ConvertTo-Json

# Get group members
Get-MgGroupMember -GroupId <ID> | ConvertTo-Json

# Get user's group memberships
Get-MgUserMemberOf -UserId <UserID>
```

### 🔍 ARM Enumeration

**Azure CLI Commands:**
```bash
# Current session
az account show

# List subscriptions
az account list --all

# List resource groups
az group list

# List resources
az resource list

# List role assignments
az role assignment list --all

# List role definitions
az role definition list
```

---

## Red Team Attack Lifecycle

### 🎯 Attack Flow

1. **Initial Access** - Compromise user credentials
2. **Enumeration** - Discover resources and permissions
3. **Privilege Escalation** - Gain higher privileges
4. **Lateral Movement** - Access other resources
5. **Persistence** - Maintain access

###  Common Attack Techniques

**1. Initial Login:**
```bash
az login
Connect-MgGraph -Scopes "Directory.Read.All"
```

**2. User Enumeration:**
```powershell
Get-MgUser -Filter "startswith(displayName,'auditor')"
Get-MgUserOwnedObject -UserId <UserID>
```

**3. Application Abuse:**
```powershell
# Find applications
Get-MgApplication -Filter "startswith(displayName,'prod-app')"

# Add credentials to owned app
Add-MgApplicationPassword -ApplicationId <AppID>
```

**4. VM Exploitation:**
```bash
# List VMs
az vm list

# Get VM IPs
az vm list-ip-addresses --name <VMName> --resource-group <RG>

# Get managed identity token (from compromised VM) - Updated API version
curl -H "Metadata:true" "http://[IP_ADDRESS]/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://management.azure.com/"

# Alternative: Get token for Microsoft Graph
curl -H "Metadata:true" "http://[IP_ADDRESS]/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://graph.microsoft.com/"

# Use token in PowerShell
$token = "<AccessToken>"
Connect-AzAccount -AccessToken $token -AccountId <SubscriptionID>

# Check managed identity permissions
Get-AzRoleAssignment -ObjectId <PrincipalID>
```

---

## 🔄 Modern Authentication Flows

### OAuth 2.0 & OpenID Connect
```
# Authorization Code Flow (most secure)
1. User → Authorization Server
2. Authorization Server → Authorization Code
3. Client → Access Token + ID Token

# Client Credentials Flow (service-to-service)
1. Service Principal → Token Endpoint
2. Token Endpoint → Access Token
```

### 🎯 Token Types:
- **Access Token** - API access (1 hour)
- **ID Token** - User identity info
- **Refresh Token** - Get new access tokens

### Modern Security Features:
- **Conditional Access** - Policy-based access control
- **Privileged Identity Management (PIM)** - Just-in-time access
- **Identity Protection** - Risk-based authentication
- **Zero Trust** - Never trust, always verify

---

## Common Security Misconfigurations

### 🔴 High-Risk Scenarios :
1. **Overprivileged Service Principals** - Apps with Global Admin rights
2. **Missing Conditional Access** - No location/device restrictions
3. **Guest User Abuse** - External B2B users with high privileges
4. **Risky Application Consent** - Users consenting to malicious apps
5. **Legacy Authentication** - Basic auth bypass (mostly disabled now)
6. **Managed Identity Abuse** - VMs/Functions with excessive permissions
7. **PIM Bypass** - Permanent vs. eligible role assignments
8. **Cross-Tenant Synchronization** - Uncontrolled identity sharing

### 🔍 Red Team Targets:
- **Global Administrators** - Ultimate target
- **Application Administrators** - Can create service principals
- **Privileged Role Administrators** - Can assign roles
- **Cloud Application Administrators** - Manage enterprise apps
- **Exchange Administrators** - Email access

### ⚠️ Critical Commands for Attackers:
```powershell
# Find Global Admins
Get-MgDirectoryRoleMember -DirectoryRoleId (Get-MgDirectoryRole -Filter "DisplayName eq 'Global Administrator'").Id

# Find owned applications
Get-MgUserOwnedObject -UserId <UserID> | Where-Object {$_.AdditionalProperties["@odata.type"] -eq "#microsoft.graph.application"}

# Check app permissions
$app = Get-MgApplication -ApplicationId <AppID>
$app.RequiredResourceAccess
```

---

## 🎯 Study Tips & Quick Reference

### 📝 Key URLs to Memorize:
- **Azure Portal:** `https://portal.azure.com`
- **Entra Admin:** `https://entra.microsoft.com`
- **M365 Admin:** `https://admin.microsoft.com`
- **M365 Apps:** `https://office.com`
- **Graph API:** `https://graph.microsoft.com/v1.0/`
- **ARM API:** `https://management.azure.com/`
- **Login Endpoint:** `https://login.microsoftonline.com/`

### Important IDs:
- **Object ID** - Unique identifier for Entra ID objects (immutable)
- **Application ID (Client ID)** - App registration identifier
- **Tenant ID** - Azure AD tenant identifier (also called Directory ID)
- **Subscription ID** - Azure subscription identifier
- **Principal ID** - Managed identity identifier

### 💡 Pro Tips:
1. Always check current context first (`Get-MgContext`, `az account show`)
2. Use `--all` flag to see inherited permissions
3. Service principals are key for persistence 😉
4. Managed identities can't be deleted by regular users (only by owners)
5. Always enumerate owned objects first
6. **CRITICAL:** Azure AD → Microsoft Entra ID (Oct 2023 rebrand)
7. **Office 365** → Microsoft 365 (includes security features)
8. Use `-All` parameter in PowerShell commands to get complete results
9. **IMDS endpoint** `[IP_ADDRESS]` only works from within Azure VMs/containers
10. **Service Principal secrets** can now have max 2-year expiry (security improvement)
11. **Application permissions** are more dangerous than delegated permissions
12. **Conditional Access** is now the primary security control method

### Red Team Mindset:
- **Think like an attacker** - What would I do with this access?
- **Enumerate everything** - Users, groups, apps, resources
- **Look for misconfigurations** - Overprivileged accounts
- **Chain attacks** - Use one compromise to get another
- **Modern security** - Understand Conditional Access, PIM, and Zero Trust
- **Token lifecycle** - Access tokens expire in 1 hour, plan accordingly

---

## 📚 Additional Resources

- **Microsoft Graph Explorer**: https://developer.microsoft.com/graph/graph-explorer
- **Entra ID Documentation**: https://learn.microsoft.com/entra/
- **Azure CLI Reference**: https://learn.microsoft.com/cli/azure/
- **Azure PowerShell**: https://learn.microsoft.com/powershell/azure/
- **Microsoft Graph PowerShell**: https://learn.microsoft.com/powershell/microsoftgraph/
- **Azure RBAC**: https://learn.microsoft.com/azure/role-based-access-control/
- **Conditional Access**: https://learn.microsoft.com/entra/identity/conditional-access/
- **Zero Trust**: https://learn.microsoft.com/security/zero-trust/

---

*Good luck! 🚀*