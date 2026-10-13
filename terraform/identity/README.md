# identity

Configuration for the Spydersoft identity server (clients, API resources,
identity resources and scopes), managed with the
[`spydersoftidentity`](https://github.com/spydersoft-consulting/terraform-provider-spydersoft-identity)
provider.

One configuration, two environments, each with its own state file:

| Environment | Admin API | State key |
| --- | --- | --- |
| `test` | `auth-admin-api.mattgerega.net` | `identity/test/terraform.tfstate` |
| `production` | `auth-admin-api.mattgerega.com` | `identity/production/terraform.tfstate` |

The pipeline (`.devops/pipeline-tf-identity.yaml`) plans and applies `test`
first. `production` is planned only after `test` has applied, and always waits
for a manual approval before it is applied.

## The provider is installed from a GitHub release

The provider is not published to a registry. Before `tofu init`, the pipeline
downloads the release zip, checks it against the release's `SHA256SUMS` and
unpacks it into `terraform.d/plugins/` (OpenTofu's implied local mirror). The
version is pinned in two places that must be changed together:

- `required_providers` in `providers.tf`
- `localProviders` in `.devops/pipeline-tf-identity.yaml`

## Credentials

The provider authenticates as a `client_credentials` client with the
`identity:admin:read` and `identity:admin:write` scopes. Each environment needs
its own client, with the credentials in Vault:

| Vault path (mount `secrets-infra`) | Fields |
| --- | --- |
| `identity/test/terraform` | `clientId`, `clientSecret` |
| `identity/production/terraform` | `clientId`, `clientSecret` |

The pipeline's Vault AppRole must be allowed to read those two paths.

## Running locally

With the Vault CLI logged in (`vault login`), dot-source the helper. It loads the
state-backend credentials, builds the provider from your local checkout into
`terraform.d/plugins` (git-ignored) and runs `tofu init` with the environment's
state key:

```powershell
. ./Initialize-Local.ps1 -Environment test      # or production
tofu plan -var-file environments/test.tfvars
```

The AppRole variables are not needed locally: the Vault provider falls back to
your CLI login. Re-run the helper whenever you switch environments (it passes
`-reconfigure`) or change the provider code; add `-SkipBuild` to reuse the
provider already in `terraform.d`.

Write `-var-file environments/test.tfvars` with a space, not `=`: PowerShell
splits the `=` form at the dot and tofu reports "Too many command line
arguments".

## Adding resources

Add `*.tf` files here that use `spydersoftidentity_*` resources. Everything in
this directory is applied to **both** environments; use `var.environment` for
anything that differs. Import objects that already exist before managing them,
for example `tofu import spydersoftidentity_client.example my-client-id`.
