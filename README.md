# Windows Access Config

Terraform for browser-based RDP to a Windows server through Cloudflare Access and a Cloudflare Tunnel private route.

```text
User browser
    │ Access authentication
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
- One exact-email allow policy.
- One proxied placeholder DNS A record (`240.0.0.0`) unless disabled.
- Clipboard transfer disabled in both directions by default.

## Prerequisites

1. A Cloudflare Tunnel already connected to the target network.
2. A private-network route for `10.168.0.27/32` (or the replacement target) assigned to the selected virtual network.
3. TCP 3389 reachable from the `cloudflared` connector to the Windows host.
4. RDP enabled on Windows and a Windows username/password available. Cloudflare Access does not manage the Windows credential.
5. A Cloudflare zone for `application_domain`.
6. An API token exported as `CLOUDFLARE_API_TOKEN` with:
   - Account — Access: Apps and Policies — Edit
   - Account — Cloudflare Tunnel — Read (and Edit if you manage routes separately)
   - Zone — DNS — Edit

## Configure

```sh
cp terraform.tfvars.example terraform.tfvars
```

Set the five values in `terraform.tfvars`. `allowed_emails` is intentionally required and has no permissive default.

If using the account's default virtual network, remove `virtual_network_id` from `terraform.tfvars`; Terraform will omit it.

To pin authentication to one IdP, add:

```hcl
allowed_idp_ids              = ["<IDENTITY_PROVIDER_ID>"]
auto_redirect_to_identity    = true
```

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
2. Authenticate with an email in `allowed_emails`.
3. Select the Windows target tile.
4. Enter the Windows credential (for a local account, use `.\username` when needed).

Verify the connector can reach the target before troubleshooting Access:

```powershell
Test-NetConnection 10.168.0.27 -Port 3389
```

Run that from a Windows host on the connector network, or use an equivalent TCP test from the connector host.

## Security notes

- Do not expose TCP 3389 directly to the Internet; route the private address through Cloudflare Tunnel.
- New RDP policies deny clipboard transfer by default here. Add only the required text clipboard formats after reviewing the data-loss risk.
- Browser RDP does not support file transfer, audio, or local printing.
- Entra-joined Windows hosts may require disabling NLA for browser RDP because PKU2U is not supported. Prefer a local/domain account where disabling NLA is unacceptable.

Cloudflare reference: https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/use-cases/rdp/rdp-browser/
