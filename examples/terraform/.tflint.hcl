# Plugins are pre-fetched by the tflint_plugin repository rule and placed
# in TFLINT_PLUGIN_DIR. source/version are omitted here so tflint discovers
# plugins by name without needing --init or network access.

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "google" {
  enabled = true
}
