resource "azuredevops_serviceendpoint_kubernetes" "public-k8-nonprod" {
  project_id            = azuredevops_project.public.id
  service_endpoint_name = "k8-nonprod"
  apiserver_url         = "https://cp-nonprod.gerega.net"
  authorization_type    = "Kubeconfig"

  kubeconfig {
    kube_config            = data.vault_kv_secret_v2.k8-nonprod-kubeconfig.data["data"]
    accept_untrusted_certs = true
  }
}