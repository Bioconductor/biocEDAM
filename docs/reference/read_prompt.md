<div id="main" class="col-md-9" role="main">

# Read a prompt template from the biocEDAM prompt library

<div class="ref-description section level2">

Loads a plain-text prompt file from `inst/prompts/` by name. Use this to
inspect the default prompt for any function, or to load it as a starting
point before modifying and passing to the `prompt=` parameter of
`edamize`, `map_concepts`, or `flat_tagger`.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
read_prompt(name)
```

</div>

</div>

<div class="section level2">

## Arguments

-   name:

    character(1) filename within `inst/prompts/`, e.g. `"edamize.txt"`,
    `"map_concepts.txt"`, `"flat_tagger.txt"`.

</div>

<div class="section level2">

## Value

character(1) the prompt text with trailing whitespace stripped.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
cat(read_prompt("map_concepts.txt"))
#> Identify ALL biological, medical, and technical concepts in the following input text.
#> For every concept found, use the OLS search tools to find the best matching ontology term.
#> 
#> Use the following ontology priorities:
#> - EDAM: computational methods, algorithms, bioinformatics operations, data types, file formats, and software topics
#> - GO: biological processes, molecular functions, and cellular components
#> - HP: human phenotypes and clinical abnormalities
#> - MONDO: diseases and disorders
#> - ChEBI: chemical entities and small molecules
#> - EFO: experimental factors, assay types, and study designs
#> - PATO: phenotypic qualities and attributes
#> 
#> IMPORTANT: if no ontology provides a clearly relevant term for a concept, omit that concept rather than forcing a poor mapping.
#> Do not map computational or statistical concepts (e.g. autocorrelation, PCA, clustering) to disease or experimental ontologies.
#> The term_iri and obo_id you report must come directly from the OLS search tool results, never constructed or guessed.
#> 
#> Return one row per concept-term pair.
```

</div>

</div>

</div>
