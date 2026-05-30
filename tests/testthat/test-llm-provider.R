test_that("llm_env_var returns correct variable names", {
    expect_equal(llm_env_var("openai"),    "OPENAI_API_KEY")
    expect_equal(llm_env_var("anthropic"), "ANTHROPIC_API_KEY")
    expect_equal(llm_env_var("claude"),    "ANTHROPIC_API_KEY")
    expect_equal(llm_env_var("gemini"),    "GOOGLE_API_KEY")
    expect_equal(llm_env_var("google"),    "GOOGLE_API_KEY")
    expect_equal(llm_env_var("ollama"),    "")
})

test_that("llm_env_var stops on unknown provider", {
    expect_error(llm_env_var("cohere"), "Unknown LLM provider")
})

test_that("llm_api_key returns empty string for ollama (no key needed)", {
    expect_equal(llm_api_key("ollama"), "")
})

test_that("llm_api_key stops with informative message when env var unset", {
    key_var <- llm_env_var("anthropic")
    old <- Sys.getenv(key_var, unset = NA)
    on.exit({
        if (is.na(old)) Sys.unsetenv(key_var)
        else Sys.setenv(tmp = old)
    })
    Sys.unsetenv(key_var)
    expect_error(llm_api_key("anthropic"), "ANTHROPIC_API_KEY")
})
