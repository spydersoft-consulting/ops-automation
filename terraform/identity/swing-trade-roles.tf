# Roles the Swing Trade API authorizes by (swing-trade/docs/BUILD_PLAN.md,
# "Authorization and roles"). The identity server emits them as the `role`
# claim in access tokens for the swingtrade API resource (swing-trade.tf).
#
# The provider creates the roles but does not assign users to them: assign
# your account in the identity admin UI (or the admin API,
# POST /api/v1/users/{id}/roles).
#
#   swingtrade.reader  read-only REST
#   swingtrade.trader  reader + create/edit/fill/close/cancel/delete trades, notes, instruments
#   swingtrade.admin   trader + settings, refresh, MCP call log
#   swingtrade.mcp     may call /mcp (independent of the REST roles)

resource "spydersoftidentity_role" "swingtrade_reader" {
  count = local.everywhere

  name = "swingtrade.reader"
}

resource "spydersoftidentity_role" "swingtrade_trader" {
  count = local.everywhere

  name = "swingtrade.trader"
}

resource "spydersoftidentity_role" "swingtrade_admin" {
  count = local.everywhere

  name = "swingtrade.admin"
}

resource "spydersoftidentity_role" "swingtrade_mcp" {
  count = local.everywhere

  name = "swingtrade.mcp"
}
