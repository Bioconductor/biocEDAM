<div id="main" class="col-md-9" role="main">

# build a graph of EDAM terms deemed relevant to a text

<div class="ref-description section level2">

build a graph of EDAM terms deemed relevant to a text

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
edam_graph(txt, edam_graph, provider = "anthropic", ...)
```

</div>

</div>

<div class="section level2">

## Arguments

-   txt:

    string, typically describing a software artifact

-   edam\_graph:

    an ontologyIndex ontology-index instance representing EDAM

-   provider:

    character(1) LLM provider; see `llm_env_var`. Defaults to
    "anthropic".

-   ...:

    passed to ontoProc::onto\_plot2

</div>

<div class="section level2">

## Value

called for its side effect (a graph plot); returns the result of
`ontoProc::onto_plot2` invisibly

</div>

<div class="section level2">

## Note

The text is expected to be generated as the 'focused' result of
vig2data; it will then be processed by 'edamize'

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
requireNamespace("ontoProc2")
eg = readRDS(system.file("rds", "edam_1.25_ontoindex.rds", package="biocEDAM"))
statescoper = readRDS(system.file("rds", "tgac-vumc_StatescopeR.rds", package="biocEDAM"))
edam_graph(statescoper$focused, eg, cex=.3)
}
```

</div>

</div>

</div>
