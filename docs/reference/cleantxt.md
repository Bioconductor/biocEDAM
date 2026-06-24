<div id="main" class="col-md-9" role="main">

# utility to "clean" odd characters in text input that seem to increase risk of LLM failures

<div class="ref-description section level2">

utility to "clean" odd characters in text input that seem to increase
risk of LLM failures

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
cleantxt(x)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    character(1) text from which non-alphabetic characters like brackets
    and parentheses are to be removed

</div>

<div class="section level2">

## Note

This is speculative; success rates appear to increase with no evident
degradation of content interpretation.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
cleantxt("RNA-seq (paired-end): analysis of #reads [v2]")
#> [1] "RNAseq pairedend) analysis of reads v2"
```

</div>

</div>

</div>
