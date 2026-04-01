# 🛡️ Azure & Cloud External Reconnaissance Cheatsheet

This cheatsheet covers techniques for identifying and footprinting target environments to determine if they are utilizing Microsoft Azure (or other cloud providers), strictly from an external perspective.

---

## 1. Entra ID (Azure AD) Enumeration

You can verify if a target organization uses Entra ID as their Identity Provider (IdP) by querying Microsoft's OpenID/Realm endpoints. 

**Endpoint**:
```http
GET https://login.microsoftonline.com/getuserrealm.srf?login=admin@<target-domain.com>&json=1
```

**What to look for in the JSON response**:
- `"NameSpaceType": "Managed"` or `"Federated"` indicates the organization actively uses Entra ID.
- `"NameSpaceType": "Unknown"` indicates they likely do not.
- `"FederationBrandName"` will often leak the internal/tenant branding string of the organization.

---

## 2. Azure App Service (Web Apps) Signatures

When auditing a web application, check the HTTP response headers and cookies. Azure App Services (formerly Azure Websites) inject very specific signatures by default:

**Cookies**:
- `ARRAffinity` or `ARRAffinitySameSite`: Used by Azure's application routing to ensure session affinity (sticky sessions) to a specific underlying worker node.

**Headers**:
- `x-ms-request-id`: A distinct Microsoft tracking header.
- `x-ms-routing-name`: Used in App Service deployment slots (e.g., staging vs production).
- `Server: Microsoft-IIS`: Common default (though can be changed/spoofed).
- `X-Powered-By: ASP.NET`: Common on traditional Azure Windows App Service deployments.

---

## 3. DNS Footprinting (Bypassing CDNs)

If a target is hiding behind a CDN like Cloudflare or Akamai, their raw IP address is masked. You can often uncover the true backend cloud provider by footprinting DNS records:

**CNAME Records**:
Lookup the CNAME (`dig +short CNAME target.com` or `nslookup -type=cname target.com`).
- **Azure**: pointing to `*.azurewebsites.net` or `*.cloudapp.net`.
- **AWS**: pointing to `*.elb.amazonaws.com`, `*.elasticbeanstalk.com`, or `*.cloudfront.net`.
- **GCP**: pointing to `ghs.google.com`.

**Name Server (NS) Records**:
Even if CNAMEs are clean, the organization's managed DNS might give it away:
- `azure-dns.com` or `azure-dns.net` (Azure)
- `awsdns` (AWS)
- `googledomains.com` (Google)

---

## 4. IP Intelligence & ASN Ownership

If you have the raw IP address (e.g., from `ping target.com`), you can query public IP intelligence databases like IP-API or WHOIS to find the Autonomous System Number (ASN) owner.

**Quick Query**:
```bash
curl -s "http://ip-api.com/line/<IP_ADDRESS>?fields=isp,org"
```

**Common Owners**:
- `Microsoft Corporation` → Azure
- `Amazon.com Inc.` or `Amazon Data Services` → AWS
- `Google LLC` → GCP
- `Cloudflare, Inc.` → Target is masked behind Cloudflare.

---
*Created for the Azure Red Team Study Notes.*
