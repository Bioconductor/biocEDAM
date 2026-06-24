<div id="main" class="col-md-9" role="main">

# Export a map\_concepts result as a JSON document

<div class="ref-description section level2">

Converts the data.frame returned by `map_concepts` into a JSON document.
Terms are grouped by ontology; each entry records the ontology IRI, term
label, OBO identifier, and the input concept that was mapped.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
mapping_to_json(x, validated_only = TRUE, path = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   x:

    data.frame as returned by `map_concepts`.

-   validated\_only:

    logical(1) if `TRUE` (default), only rows where `validated == TRUE`
    are included.

-   path:

    character(1) or `NULL`. When not `NULL`, the JSON is written to this
    file path and `NULL` is returned invisibly. When `NULL` (default)
    the JSON string is returned.

</div>

<div class="section level2">

## Value

A JSON character string, or `NULL` invisibly when `path` is supplied.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
df <- data.frame(
  input_text = c("atrial fibrillation", "genome sequencing"),
  term_label = c("Atrial Fibrillation", "Whole Genome Sequencing"),
  term_iri   = c("http://purl.obolibrary.org/obo/HP_0005110",
                 "http://purl.obolibrary.org/obo/OBI_0002117"),
  obo_id     = c("HP:0005110", "OBI:0002117"),
  ontology   = c("HP", "OBI"),
  rationale  = c("matches concept", "matches concept"),
  validated  = c(TRUE, TRUE),
  definition = c(NA_character_, NA_character_),
  stringsAsFactors = FALSE
)
cat(mapping_to_json(df))
#> {
#>   "HP": [
#>     {
#>       "input_text": "atrial fibrillation",
#>       "term_label": "Atrial Fibrillation",
#>       "term_iri": "http://purl.obolibrary.org/obo/HP_0005110",
#>       "obo_id": "HP:0005110"
#>     }
#>   ],
#>   "OBI": [
#>     {
#>       "input_text": "genome sequencing",
#>       "term_label": "Whole Genome Sequencing",
#>       "term_iri": "http://purl.obolibrary.org/obo/OBI_0002117",
#>       "obo_id": "OBI:0002117"
#>     }
#>   ]
#> }
```

</div>

</div>

</div>
