<div id="main" class="col-md-9" role="main">

# full workflow to tag a bioconductor package and selected representative content with EDAM terms

<div class="ref-description section level2">

full workflow to tag a bioconductor package and selected representative
content with EDAM terms

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
tag_bioc(
  pkgname = "tximeta",
  url =
    "https://bioconductor.org/packages/release/bioc/vignettes/tximeta/inst/doc/tximeta.html",
  provider = "anthropic"
)
```

</div>

</div>

<div class="section level2">

## Arguments

-   pkgname:

    character(1)

-   url:

    URL for representative content, in html or pdf

-   provider:

    character(1) LLM provider; see `llm_env_var`. Defaults to "openai".

</div>

<div class="section level2">

## Value

a data.frame with biocViews and EDAM suggestions

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
ti = tag_bioc()
bs = tag_bioc(pkg="Biostrings",
  url="https://bioconductor.org/packages/release/bioc/vignettes/Biostrings/inst/doc/Biostrings2Classes.pdf")
library(DT)
ndf = rbind(ti, bs)
datatable(ndf)
}
```

</div>

</div>

</div>
