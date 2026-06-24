<div id="main" class="col-md-9" role="main">

# Helper recursive function to extract 'uri' nodes from JSON document based on edamize

<div class="ref-description section level2">

Helper recursive function to extract 'uri' nodes from JSON document
based on edamize

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
extract_uri(node)
```

</div>

</div>

<div class="section level2">

## Arguments

-   node:

    a JSON document (list)

</div>

<div class="section level2">

## Value

a list of URI strings extracted from `node`

</div>

<div class="section level2">

## Note

From perplexity.ai

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
node <- list(uri = "http://edamontology.org/topic_3308",
             children = list(
                 list(uri = "http://edamontology.org/topic_3170")))
extract_uri(node)
#> [[1]]
#> [1] "http://edamontology.org/topic_3170"
#> 
#> [[2]]
#> [1] "http://edamontology.org/topic_3308"
#> 
```

</div>

</div>

</div>
