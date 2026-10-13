# Imported from the test identity server. Managed in test only for now.

resource "spydersoftidentity_identity_resource" "openid" {
  count = local.test_only

  name         = "openid"
  display_name = "Your user identifier"
  required     = true
  user_claims  = ["sub"]
}

resource "spydersoftidentity_identity_resource" "profile" {
  count = local.test_only

  name         = "profile"
  display_name = "User profile"
  description  = "Your user profile information (first name, last name, etc.)"
  emphasize    = true
  user_claims  = ["birthdate", "family_name", "gender", "given_name", "locale", "middle_name", "name", "nickname", "picture", "preferred_username", "profile", "updated_at", "website", "zoneinfo"]
}

resource "spydersoftidentity_identity_resource" "roles" {
  count = local.test_only

  name                       = "roles"
  display_name               = "User Roles"
  show_in_discovery_document = false
  user_claims                = ["role"]
}

resource "spydersoftidentity_identity_resource" "email" {
  count = local.test_only

  name         = "email"
  display_name = "Your email address"
  emphasize    = true
  user_claims  = ["email", "email_verified"]
}

resource "spydersoftidentity_identity_resource" "phone" {
  count = local.test_only

  name         = "phone"
  display_name = "Your phone number"
  emphasize    = true
  user_claims  = ["phone_number", "phone_number_verified"]
}

resource "spydersoftidentity_identity_resource" "address" {
  count = local.test_only

  name         = "address"
  display_name = "Your postal address"
  emphasize    = true
  user_claims  = ["address"]
}