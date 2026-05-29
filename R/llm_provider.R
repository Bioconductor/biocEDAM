#' Map an LLM provider name to its environment variable
#' @param provider character(1) one of "openai", "anthropic", "claude", "gemini", "google", "ollama"
#' @return character(1) environment variable name, or "" for keyless providers
#' @export
llm_env_var = function(provider) {
  switch(provider,
    openai    = "OPENAI_API_KEY",
    anthropic = "ANTHROPIC_API_KEY",
    claude    = "ANTHROPIC_API_KEY",
    gemini    = "GOOGLE_API_KEY",
    google    = "GOOGLE_API_KEY",
    ollama    = "",
    stop(sprintf(
      "Unknown LLM provider: '%s'. Supported: openai, anthropic, claude, gemini, google, ollama",
      provider
    ))
  )
}

#' Retrieve the API key for an LLM provider from the environment
#' @param provider character(1) provider name; see \code{llm_env_var}
#' @return character(1) the key value; empty string for keyless providers (e.g. ollama)
#' @note Stops with an informative error if the required environment variable is not set.
#' @export
llm_api_key = function(provider) {
  var = llm_env_var(provider)
  if (nchar(var) == 0L) return("")
  key = Sys.getenv(var)
  if (nchar(key) == 0L)
    stop(sprintf(
      "Environment variable %s is not set (required for provider '%s')",
      var, provider
    ))
  key
}

#' Create an ellmer chat object for a given LLM provider
#' @param provider character(1) provider name; see \code{llm_env_var}
#' @param model character(1) model identifier appropriate for the chosen provider
#' @param \dots additional arguments passed to the underlying \code{chat_*} function
#' @return an ellmer Chat object
#' @note The \code{model} default in calling functions is typically an OpenAI model name.
#' When using a different provider, supply an appropriate model name for that provider.
#' @export
llm_chat = function(provider = "openai", model, ...) {
  llm_api_key(provider)
  switch(provider,
    openai    = ellmer::chat_openai(model = model, ...),
    anthropic = ellmer::chat_anthropic(model = model, ...),
    claude    = ellmer::chat_anthropic(model = model, ...),
    gemini    = ellmer::chat_google_gemini(model = model, ...),
    google    = ellmer::chat_google_gemini(model = model, ...),
    ollama    = ellmer::chat_ollama(model = model, ...),
    stop(sprintf("Unknown LLM provider: '%s'", provider))
  )
}
