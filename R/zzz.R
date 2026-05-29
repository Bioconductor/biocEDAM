.onLoad <- function(libname, pkgname) {
  reticulate::py_require(c(
    "jsonschema==4.23.0", "pandas==2.2.3", "requests==2.32.3",
    "openai==1.66.3", "anthropic", "google-genai"
  ))
}
