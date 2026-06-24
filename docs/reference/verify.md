<div id="main" class="col-md-9" role="main">

# given a data.frame with uri and tm produced by edamize (or mkdf), check against the frozen EDAM term tables in biocEDAM, filtering records to those whose uri matches a known id.

<div class="ref-description section level2">

given a data.frame with uri and tm produced by edamize (or mkdf), check
against the frozen EDAM term tables in biocEDAM, filtering records to
those whose uri matches a known id.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
verify(datf)
```

</div>

</div>

<div class="section level2">

## Arguments

-   datf:

    data.frame with at least a `uri` column containing EDAM URIs (e.g.
    `"http://edamontology.org/topic_3308"`)

</div>

<div class="section level2">

## Value

a data.frame with the same structure as `datf`, restricted to rows whose
`uri` matches a term in the bundled EDAM vocabulary tables

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
df <- data.frame(
    uri = c("http://edamontology.org/topic_3308",
            "http://edamontology.org/topic_9999"),   # 9999 is not a real term
    tm  = c("Transcriptomics", "Made-up term"),
    stringsAsFactors = FALSE)
verify(df)  # returns only the row whose uri is in the known vocabulary
#>                                  uri              tm
#> 1 http://edamontology.org/topic_3308 Transcriptomics
```

</div>

</div>

</div>
