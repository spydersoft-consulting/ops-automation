resource "azurerm_subscription" "gerega-lab" {
  alias = "gerega-lab"
  subscription_name = "gerega-lab"
  subscription_id = var.subscription_id
}