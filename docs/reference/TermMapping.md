<div id="main" class="col-md-9" role="main">

# Ellmer type schema for a single ontology term mapping

<div class="ref-description section level2">

Describes one matched ontology term returned by an OLS4 MCP tool call.
Use with `chat$chat_structured()` to obtain validated, typed output.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
TermMapping
```

</div>

</div>

<div class="section level2">

## Format

An ellmer `TypeObject` with fields:

-   input\_text:

    The biological or medical concept extracted from the input string

-   term\_label:

    The matched ontology term label

-   term\_iri:

    The IRI/URI of the matched term

-   obo\_id:

    The OBO-format ID, e.g. `GO:0007507`

-   ontology:

    Ontology short name, e.g. `GO`, `HP`, `MONDO`

-   rationale:

    Why this term was selected for this concept

</div>

<div class="section level2">

## See also

<div class="dont-index">

`TermMappingTable`, `ols4_mcp_tools`

</div>

</div>

</div>
