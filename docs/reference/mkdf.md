<div id="main" class="col-md-9" role="main">

# simple utility to process output of edamize into a data.frame

<div class="ref-description section level2">

simple utility to process output of edamize into a data.frame

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
mkdf(x)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    a data.frame as produced by edamize (returned as-is), or a legacy
    list

</div>

<div class="section level2">

## Note

dplyr::distinct is run on the result

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
df <- data.frame(uri = "http://edamontology.org/topic_3308",
                 tm  = "Transcriptomics", stringsAsFactors = FALSE)
mkdf(df)  # data.frame input is passed through unchanged
#>                                  uri              tm
#> 1 http://edamontology.org/topic_3308 Transcriptomics
```

</div>

</div>

</div>
