# Windows Access Config

Terraform for browser-based RDP to a Windows server through Cloudflare Access and a Cloudflare Tunnel private route.

```text
User browser
    │ Entra ID authentication + Access authorization
    ▼
rdp.example.com (proxied DNS + Access)
    │ browser RDP proxy
    ▼
Cloudflare Tunnel private route / virtual network
    │ TCP 3389
    ▼
Windows Server 10.168.0.27
```

The repository currently defaults to the existing `remo-win-vm` private address `10.168.0.27`. You can replace it with a Windows VM behind Proxmox without changing the Access model: route that private IP through a Tunnel and update `target_ipv4` and, when needed, `virtual_network_id`.

## Creates

- One Access infrastructure target for the Windows server.
- One browser-rendered RDP Access application with a target criterion on TCP 3389.
- One Entra-only login method with instant authentication.
- One Entra email/UPN or security-group allow policy.
- One proxied placeholder DNS A record (`240.0.0.0`) unless disabled.
- Clipboard transfer disabled in both directions by default.

## Prerequisites

1. A Cloudflare Tunnel already connected to the target network.
2. A private-network route for `10.168.0.27/32` (or the replacement target) assigned to the selected virtual network.
3. TCP 3389 reachable from the `cloudflared` connector to the Windows host.
4. RDP enabled on an Entra-joined Windows host. Cloudflare Access authenticates and authorizes the user at the edge, but Windows still performs a second authentication using that user's Entra-backed Windows credential.
5. A Cloudflare zone for `application_domain`.
6. A Cloudflare API token stored as `cloudflare_api_token` in the local, Git-ignored `terraform.tfvars`, with:
   - Account — Access: Apps and Policies — Edit
   - Account — Access: Organizations, Identity Providers, and Groups — Read (Edit only if this project creates the Entra IdP)
   - Account — Cloudflare Tunnel — Read (and Edit if you manage routes separately)
   - Zone — DNS — Edit

## Configure

```sh
cp terraform.tfvars.example terraform.tfvars
```

Set the values in `terraform.tfvars`. `entra_allowed_emails` is intentionally required unless `entra_allowed_group_ids` is populated; there is no permissive domain-wide default.

### API token

This repository expects the token in the local, Git-ignored `terraform.tfvars`:

```hcl
cloudflare_api_token = "<token>"
```

Copy `terraform.tfvars.example` to `terraform.tfvars` and replace the `cloudflare_api_token` placeholder. The provider also supports `CLOUDFLARE_API_TOKEN` for automation, but the documented local workflow for this repo is the ignored tfvars file.

Create the token in **Cloudflare dashboard → My Profile → API Tokens → Create Token → Custom token**. Scope it to the Cloudflare account and `application_domain` zone used by this deployment. Do not use a Global API Key, commit the token, or copy a token from another account without checking its scopes. Before committing, verify `git check-ignore terraform.tfvars` succeeds.

### Where each value comes from

| Variable | What it is | Where to find it |
| --- | --- | --- |
| `cloudflare_api_token` | Cloudflare API credential used by Terraform | **My Profile → API Tokens**; save it only in the Git-ignored `terraform.tfvars` |
| `account_id` | Cloudflare account that owns Zero Trust, the Tunnel route, Entra IdP, and Access app | Cloudflare dashboard URL after `dash.cloudflare.com/`, or **Account home → Account ID** |
| `zone_id` | Cloudflare zone that owns `application_domain` | **Websites → your zone → Overview → Zone ID** |
| `application_domain` | New public hostname used to open browser RDP | Choose an unused hostname in that zone, such as `rdp.example.com`; Terraform creates its proxied placeholder DNS record |
| `target_ipv4` | Private IP of the Windows host | Windows `ipconfig`, Azure/GCP NIC details, or the Proxmox VM network configuration |
| `virtual_network_id` | **Cloudflare Zero Trust virtual-network UUID** containing the Tunnel CIDR route to `target_ipv4` | **Zero Trust → Networks → Routes**; locate the route covering the target IP and use its virtual network. This is not an Azure VNet ID, Azure subscription ID, GCP VPC ID, or Proxmox network name |
| `existing_entra_idp_id` | Existing Cloudflare Access Microsoft Entra IdP UUID | **Zero Trust → Integrations → Identity providers → Entra ID**; use the UUID from the edit-page URL or API response |
| `entra_allowed_emails` | Exact Entra users authorized by Access | Use each user's Entra email/UPN as returned by the configured email claim |
| `entra_allowed_group_ids` | Optional replacement for the email allowlist | Microsoft Entra admin center → **Identity → Groups → All groups → group → Object ID** |

### Find the Cloudflare virtual network correctly

The target and route must use the same Cloudflare virtual network. A virtual network copied from an unrelated Azure or Proxmox project will produce a valid Terraform plan but an unreachable RDP target.

1. In Cloudflare Zero Trust, open **Networks → Routes**.
2. Find a CIDR route containing the Windows IP. For `10.168.0.27`, an exact `10.168.0.27/32` route or a containing subnet such as `10.168.0.0/24` is valid.
3. Confirm the route points to a healthy Tunnel whose connector can reach the Windows host on TCP `3389`.
4. Copy that route's Cloudflare virtual-network UUID into `virtual_network_id`.
5. If no route covers the IP, create one first. Prefer the narrowest suitable CIDR.

API lookups, when the token has **Cloudflare Tunnel Read**:

```sh
# List virtual networks and their UUIDs.
curl -fsS \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/teamnet/virtual_networks"

# Resolve the route Cloudflare would use for the target IP.
curl -fsS \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/teamnet/routes/ip/$TARGET_IP"
```

If a sibling Terraform project owns the route, its state exposes the same value:

```sh
terraform state show <route-resource-address>
# Read: virtual_network_id = "..."
```

If the matching route uses the account's default Cloudflare virtual network, `virtual_network_id` may be omitted. Do not omit it merely because Azure calls the source network a VNet.

### Verify the network before applying

From the Tunnel connector or another machine on the connector network, verify the origin path:

```powershell
Test-NetConnection <TARGET_IP> -Port 3389
```

Also confirm that the target IP falls inside the selected route. Terraform validates UUID syntax and resource schema; it cannot prove that a connector can reach the server.

By default, this project reuses an existing Cloudflare Access Entra IdP. Set its ID:

```hcl
existing_entra_idp_id = "<CLOUDFLARE_ENTRA_IDP_ID>"
```

The application is always pinned to that Entra IdP and uses instant authentication. To authorize an Entra security group instead of individual users, set its Object ID:

```hcl
entra_allowed_group_ids = ["<ENTRA_SECURITY_GROUP_OBJECT_ID>"]
```

Group authorization requires **Support groups** on the Cloudflare Entra integration and the Microsoft Graph permissions documented by Cloudflare. SCIM is recommended for readable group names and deprovisioning but is not required when using Object IDs.

To create a new Entra integration in this project instead, set `manage_entra_idp = true` and supply `entra_client_id`, `entra_client_secret`, and `entra_directory_id` in the ignored `terraform.tfvars`. The Entra redirect URI is `https://<team-name>.cloudflareaccess.com/cdn-cgi/access/callback`.

If the DNS record already exists, set `create_dns_record = false` and import/manage the record separately.

## Deploy

```sh
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

No API token is stored in Terraform files. The real `terraform.tfvars`, state, plans, and `.env` are ignored.

## Connect and verify

1. Open the Zero Trust App Launcher: `https://<team-name>.cloudflareaccess.com`.
2. Authenticate with Entra. Access must identify the user by a value in `entra_allowed_emails`, or the user must belong to an allowed Entra group.
3. Select the Windows target tile.
4. Enter `AzureAD\\user@example.com` or `AzureAD\\user`. The browser initiates RDP and Windows prompts for that user's Entra password.

Verify the connector can reach the target before troubleshooting Access:

```powershell
Test-NetConnection 10.168.0.27 -Port 3389
```

Run that from a Windows host on the connector network, or use an equivalent TCP test from the connector host.

## Security notes

- Do not expose TCP 3389 directly to the Internet; route the private address through Cloudflare Tunnel.
- New RDP policies deny clipboard transfer by default here. Add only the required text clipboard formats after reviewing the data-loss risk.
- Browser RDP does not support file transfer, audio, or local printing.
- Cloudflare Access Entra authentication does **not** pass the Access token into Windows and is not passwordless Windows SSO. It is the first gate; Windows Entra authentication is the second gate.
- Entra-joined Windows hosts require disabling enforcement of NLA for browser RDP because PKU2U is not supported. Disable only NLA; keep the RDP security layer at **Negotiate** or **SSL/TLS**, never legacy RDP security.

Cloudflare reference: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/rdp/rdp-browser/
