<div id="main" class="col-md-9" role="main">

# process the output of edamize followed by mkdf to create a data frame with components topic, operation, data, format, reflecting main elements of EDAM

<div class="ref-description section level2">

process the output of edamize followed by mkdf to create a data frame
with components topic, operation, data, format, reflecting main elements
of EDAM

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
toline(x)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    output of mkdf

</div>

<div class="section level2">

## Value

a data.frame

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
df <- data.frame(
    uri = c("http://edamontology.org/topic_3308",
            "http://edamontology.org/operation_2238",
            "http://edamontology.org/data_3112",
            "http://edamontology.org/format_3475"),
    tm  = c("Transcriptomics", "Statistical calculation",
            "Gene expression matrix", "TSV"),
    stringsAsFactors = FALSE)
toline(df)
#>                    topic                      operation
#> 1 Transcriptomics (3308) Statistical calculation (2238)
#>                            data     format
#> 1 Gene expression matrix (3112) TSV (3475)
```

</div>

</div>

</div>
