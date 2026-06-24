<div id="main" class="col-md-9" role="main">

# Validate and enrich a TermMappingTable via the OLS4 REST API

<div class="ref-description section level2">

For each row in `result`, queries the EBI OLS4 REST API by `term_iri` to
confirm the term exists and retrieve an authoritative definition. All
rows are retained; two columns are added:

-   validated:

    logical — `TRUE` if the IRI was found in OLS4, `FALSE` if not
    (possible hallucination or deprecated term)

-   definition:

    character — the OLS4-sourced definition for validated terms; `NA`
    for unvalidated rows

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
ols4_enrich(result, label_match = FALSE)
```

</div>

</div>

<div class="section level2">

## Arguments

-   result:

    data.frame as returned by `map_concepts`.

-   label\_match:

    logical(1) if `TRUE`, add `llm_label` and `label_match` columns
    (content-word overlap check between the LLM label and the OLS4
    canonical label). Defaults to `FALSE`.

</div>

<div class="section level2">

## Value

`result` with `validated` and `definition` columns added, and optionally
`llm_label` and `label_match`.

</div>

<div class="section level2">

## Details

Three columns are added or updated:

-   llm\_label:

    The original label as produced by the LLM, preserved before being
    replaced by the OLS4 canonical label

-   label\_match:

    logical — `TRUE` if the LLM label and the OLS4 canonical label share
    at least one content word (a basic semantic consistency check);
    `FALSE` flags cases where the LLM supplied a real but unrelated IRI
    (e.g. "variant calling" → "Cystatin-SN"); `NA` for unvalidated rows

-   definition:

    OLS4-sourced definition; `NA` for unvalidated rows

Rows where `validated = TRUE` but `label_match = FALSE` are the most
suspicious: the IRI exists in OLS4 but likely does not correspond to the
extracted concept.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
    ch  <- ols4_chat()
    raw <- map_concepts("atrial fibrillation and genome sequencing", chat = ch)
    enr <- ols4_enrich(raw)
    enr[enr$validated, ]   # confirmed terms only
}
```

</div>

</div>

</div>
