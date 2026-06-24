<div id="main" class="col-md-9" role="main">

# Examining biotools tagging of Bioconductor packages

<div class="section level2">

## Introduction

Inspired by Herve Menager’s
[issue](https://github.com/vjcitn/biocEDAM/issues/1), I examined the
[ELIXIR Research Software
Ecosystem](https://research-software-ecosystem.github.io/) source repo
for [metadata on biotools
components](https://github.com/research-software-ecosystem/content/tree/master/data).
Information here was filtered using code in the inst/scrapes folder of
the biocEDAM package. This information and the `biotools_bioc`
data.frame in this package should be updated regularly.

</div>

<div class="section level2">

## A table with EDAM topics for the Bioconductor packages in biotools metadata

<div id="cb1" class="sourceCode">

``` r
library(DT)
library(biocEDAM)
data(biotools_bioc)
datatable(biotools_bioc)
```

</div>

<div id="htmlwidget-ac96cb3ee4656e2e9ec3"
class="datatables html-widget html-fill-item"
style="width:100%;height:auto;">

</div>

</div>

</div>
