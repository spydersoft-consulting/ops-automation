# Imported from the test identity server. Managed in test only for now.

resource "spydersoftidentity_api_resource" "api" {
  count = local.test_only

  name         = "api"
  display_name = "My API"
}

resource "spydersoftidentity_api_resource" "audit_api" {
  count = local.test_only

  name         = "audit-api"
  display_name = "Audit API"
}

resource "spydersoftidentity_api_resource" "pitstop_data_api" {
  count = local.test_only

  name         = "pitstop-data-api"
  display_name = "Pitstop Data API"
  scopes       = ["pitstop:read", "pitstop:write"]
}

resource "spydersoftidentity_api_resource" "unifi_ipmanager" {
  count = local.test_only

  name         = "unifi.ipmanager"
  display_name = "Unifi IP Manager"
  scopes       = ["unifi.ipmanager"]
}

resource "spydersoftidentity_api_resource" "filestore_api" {
  count = local.test_only

  name         = "filestore-api"
  display_name = "FileStore API"
  scopes       = ["filestore:read", "filestore:write"]
}

resource "spydersoftidentity_api_resource" "notification_api" {
  count = local.test_only

  name         = "notification-api"
  display_name = "Notification API"
  scopes       = ["notification:read", "notification:write"]
}