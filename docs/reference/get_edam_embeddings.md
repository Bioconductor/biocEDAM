<div id="main" class="col-md-9" role="main">

# Retrieve pre-computed EDAM term embeddings from AnnotationHub

<div class="ref-description section level2">

Downloads (and caches locally via AnnotationHub) a matrix of
`text-embedding-3-small` embeddings for all non-deprecated EDAM terms.
Each term is represented by its label concatenated with its
`oio:hasDefinition` text. On first call the file is downloaded;
subsequent calls in the same or future sessions use the local cache.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
get_edam_embeddings()
```

</div>

</div>

<div class="section level2">

## Value

a list with components `ids`, `labels`, `types`, `texts`, `embeddings`
(numeric matrix, terms × dimensions), `model`, and `created`.

</div>

<div class="section level2">

## Details

Lookup order:

1.  If `EDAM_EMBEDDING_RDS` is set to a readable `.rds` path, that file
    is loaded and returned immediately.

2.  The file bundled with the package at
    `inst/demo_embedding/edam_embeddings.rds` is used (via
    `system.file`).

3.  AnnotationHub is queried for a `biocEDAM` embedding resource.

To override the bundled demo file with a freshly generated artifact, set
`EDAM_EMBEDDING_RDS` to its path or ensure the resource is in
AnnotationHub (see `make_edam_embeddings`).

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
emb <- get_edam_embeddings()
#> Loading bundled EDAM embeddings from /private/var/folders/yw/gfhgh7k565v9w83x_k764wbc0000gp/T/RtmpMjVNCm/temp_libpathad7f6dc6f6fe/biocEDAM/demo_embedding/edam_embeddings.rds
cat(sprintf("%d terms | %d dimensions | model: %s\n",
    length(emb$ids), ncol(emb$embeddings), emb$model))
#> 2399 terms | 1536 dimensions | model: text-embedding-3-small
```

</div>

</div>

</div>
