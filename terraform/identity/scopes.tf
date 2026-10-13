# Imported from the test identity server. Managed in test only for now.

resource "spydersoftidentity_scope" "pitstop_read" {
  count = local.test_only

  name                       = "pitstop:read"
  display_name               = "Read Pitstop Data"
  show_in_discovery_document = false
}

resource "spydersoftidentity_scope" "pitstop_write" {
  count = local.test_only

  name                       = "pitstop:write"
  display_name               = "Write Pitstop Data"
  show_in_discovery_document = false
}

resource "spydersoftidentity_scope" "audit_read" {
  count = local.test_only

  name                       = "audit:read"
  display_name               = "Read Audit Data"
  show_in_discovery_document = false
}

resource "spydersoftidentity_scope" "identity_read" {
  count = local.test_only

  name                       = "identity:read"
  display_name               = "Read Identity Data"
  show_in_discovery_document = false
}

resource "spydersoftidentity_scope" "identity_write" {
  count = local.test_only

  name                       = "identity:write"
  display_name               = "Write Identity Data"
  show_in_discovery_document = false
}

resource "spydersoftidentity_scope" "unifi_ipmanager" {
  count = local.test_only

  name                       = "unifi.ipmanager"
  display_name               = "Unifi IP Manager API"
  show_in_discovery_document = false
}

resource "spydersoftidentity_scope" "filestore_read" {
  count = local.test_only

  name         = "filestore:read"
  display_name = "Read files from FileStore"
}

resource "spydersoftidentity_scope" "filestore_write" {
  count = local.test_only

  name         = "filestore:write"
  display_name = "Write files to FileStore"
}

resource "spydersoftidentity_scope" "notification_read" {
  count = local.test_only

  name         = "notification:read"
  display_name = "Notification Service Read"
}

resource "spydersoftidentity_scope" "notification_write" {
  count = local.test_only

  name         = "notification:write"
  display_name = "Notification Service Write"
}