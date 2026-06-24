<div id="main" class="col-md-9" role="main">

# Use the extract\_data facility defined in ellmer's doc to obtain summary information about textual content. Originally tailored to vignettes in bioconductor; it is newly generalized to handle any pdf, html or text in URL.

<div class="ref-description section level2">

Use the extract\_data facility defined in ellmer's doc to obtain summary
information about textual content. Originally tailored to vignettes in
bioconductor; it is newly generalized to handle any pdf, html or text in
URL.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
vig2data(
  url = "https://bioconductor.org/packages/release/bioc/html/Voyager.html",
  maxnchar = 30000,
  n_pdf_pages = 10,
  model = "claude-sonnet-4-5",
  provider = "anthropic",
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   url:

    character(1) URL for an html bioconductor vignettes

-   maxnchar:

    numeric(1) text is truncated to a substring with this length

-   n\_pdf\_pages:

    numeric(1) maximum number of pages to extract text from for pdf
    vignettes

-   model:

    character(1) model identifier for the selected provider; defaults to
    "gpt-4o" (OpenAI)

-   provider:

    character(1) LLM provider; see `llm_env_var` for supported values
    and the required environment variable for each. Defaults to
    "openai".

-   ...:

    passed to the underlying `chat_*` function via `llm_chat`

</div>

<div class="section level2">

## Value

a list with components author, topics, focused, coherence, and
persuasion

</div>

<div class="section level2">

## Note

Based on code from
https://cran.r-project.org/web/packages/ellmer/vignettes/structured-data.html
March 15 2025. The API key for the chosen provider must be available in
the corresponding environment variable (e.g. OPENAI\_API\_KEY for
"openai", ANTHROPIC\_API\_KEY for "anthropic").

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
# ANTHROPIC_API_KEY must be set for the default provider
tst = vig2data()
str(tst)
}
```

</div>

</div>

</div>
