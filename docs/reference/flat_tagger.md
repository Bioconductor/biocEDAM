<div id="main" class="col-md-9" role="main">

# simple tagger based on text excerpt and available context from data-frames with edam vocabularies

<div class="ref-description section level2">

simple tagger based on text excerpt and available context from
data-frames with edam vocabularies

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
flat_tagger(
  txt,
  nterms = 20,
  model = "claude-sonnet-4-5",
  provider = "anthropic",
  prompt = read_prompt("flat_tagger.txt"),
  ...
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   txt:

    a text string for analysis

-   nterms:

    integer(1) approximate number of EDAM terms to return. Defaults
    to 20.

-   model:

    character(1) model identifier for the selected provider; defaults to
    "claude-sonnet-4-5" (Anthropic)

-   provider:

    character(1) LLM provider; see `llm_env_var` for supported values
    and the required environment variable for each. Defaults to
    "anthropic".

-   prompt:

    character(1) instruction text sent to the LLM. Defaults to the
    contents of `inst/prompts/flat_tagger.txt`; must contain two
    `%s`/`%d` placeholders for `nterms` and `txt`. Use
    `read_prompt("flat_tagger.txt")` to inspect the default.

-   ...:

    parameters passed to the underlying `chat_*` function via `llm_chat`

</div>

<div class="section level2">

## Value

a data.frame with columns `id` (EDAM CURIE) and `lbl` (term label)

</div>

<div class="section level2">

## Note

This function as of Nov 7 2025 will routinely hallucinate associations
and terms.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
txt = "The Voyager package is an R/Bioconductor software designed for exploratory spatial 
data analysis (ESDA) of spatial single-cell omics datasets. It operates on the 
SpatialFeatureExperiment (SFE) S4 class, allowing users to perform a wide range of spatial 
statistical analyses directly within a biological context. Univariate global spatial statistics 
supported include Moran's I for measuring spatial autocorrelation, permutation testing 
for assessing significance, and correlograms for examining spatial correlation structure. 
Bivariate spatial statistics implemented in Voyager comprise Lees L statistic 
and cross variograms for evaluating spatial associations between two 
variables. In addition, Voyager provides tools for multivariate analysis using methods 
such as MULTISPATI PCA, which integrates spatial structure into principal component 
analysis, and Anselins recent multivariate local Gearys C" 
flat_tagger(txt, nterms=12, model="gpt-4o")
}
```

</div>

</div>

</div>
