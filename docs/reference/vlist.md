<div id="main" class="col-md-9" role="main">

# snapshot of all biocViews

<div class="ref-description section level2">

snapshot of all biocViews

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
data(vlist)
```

</div>

</div>

<div class="section level2">

## Format

An object of class `list` of length 4.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
data(vlist)
sapply(vlist,nrow)
#>      BioCsoft       BioCann       BioCexp BioCworkflows 
#>          2266           920           429            30 
dim(vlist[[1]])
#> [1] 2266   47
```

</div>

</div>

</div>
