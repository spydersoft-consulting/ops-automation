# Per-environment switches for resources that do not exist everywhere yet.
# Use them as the count of a resource:
#
#   count = local.test_only        # managed in test only
#   count = local.everywhere       # managed in every environment
#
# Promote an object to production by changing local.test_only to
# local.everywhere. The resource address (<type>.<name>[0]) stays the same, so
# the test state is untouched.
locals {
  everywhere = 1
  test_only  = var.environment == "test" ? 1 : 0
}
