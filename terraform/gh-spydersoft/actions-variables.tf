resource "github_actions_variable" "windows_dns_api_nuget" {
  repository    = "spyder007/windows-dns-api"
  variable_name = "NUGET_URL"
  value         = "https://nuget.pkg.github.com/spydersoft-consulting/index.json"
}