# The API token is read from CLOUDFLARE_API_TOKEN. It is never a variable,
# so it cannot end up in a tfvars file, a plan file or state outputs.
provider "cloudflare" {}
