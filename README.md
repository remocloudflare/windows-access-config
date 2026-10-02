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
6. An API token exported as `CLOUDFLARE_API_TOKEN` with:
   - Account — Access: Apps and Policies — Edit
   - Account — Cloudflare Tunnel — Read (and Edit if you manage routes separately)
   - Zone — DNS — Edit

## Configure

```sh
cp terraform.tfvars.example terraform.tfvars
```

Set the values in `terraform.tfvars`. `entra_allowed_emails` is intentionally required unless `entra_allowed_group_ids` is populated; there is no permissive domain-wide default.

If using the account's default virtual network, remove `virtual_network_id` from `terraform.tfvars`; Terraform will omit it.

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
