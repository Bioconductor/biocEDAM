<div id="main" class="col-md-9" role="main">

# use BiocPkgTools to acquire metadata on a specified Bioconductor package

<div class="ref-description section level2">

use BiocPkgTools to acquire metadata on a specified Bioconductor package

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
bioc_line(pkgname = "tximeta")
```

</div>

</div>

<div class="section level2">

## Arguments

-   pkgname:

    character(1)

</div>

<div class="section level2">

## Value

a 1-line tibble with all the fields defined in BiocPkgTools::biocPkgList
output

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
    bl <- bioc_line("tximeta")
    bl$Package
}
```

</div>

</div>

</div>
