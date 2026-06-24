<div id="main" class="col-md-9" role="main">

# use Anh Vu's prompting to develop structured metadata about Bioconductor packages, targeting EDAM ontology and bio.tools schema

<div class="ref-description section level2">

use Anh Vu's prompting to develop structured metadata about Bioconductor
packages, targeting EDAM ontology and bio.tools schema

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
curate_bioc(
  packageName = "chromVAR",
  devurl =
    "https://raw.githubusercontent.com/GreenleafLab/chromVAR/refs/heads/master/README.md",
  model = "claude-sonnet-4-5",
  provider = "anthropic"
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   packageName:

    character(1) a Bioconductor software package name, its release
    landing page will be scraped

-   devurl:

    character(1) a URL for doc originating from the developer

-   model:

    character(1) model identifier for the selected provider; defaults to
    "gpt-4o" (OpenAI)

-   provider:

    character(1) LLM provider for the Python path; currently only
    "openai" is supported. The value of the corresponding environment
    variable (see `llm_env_var`) is used as the API key and the function
    stops with an informative error if the variable is not set.

</div>

<div class="section level2">

## Value

two python dicts, base\_final and edam\_processed

</div>

<div class="section level2">

## Note

Schema completion is done with temperature set to 0.0; see edamize
function for more flexibility.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
  # OPENAI_API_KEY must be set for the default provider
  lk = curate_bioc()
  str(lk)
}
```

</div>

</div>

</div>
