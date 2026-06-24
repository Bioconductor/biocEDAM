<div id="main" class="col-md-9" role="main">

# helper for package listing

<div class="ref-description section level2">

helper for package listing

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
pksByViews(views, type = "BioCsoft", vlist = NULL)
```

</div>

</div>

<div class="section level2">

## Arguments

-   views:

    character() biocViews node values

-   type:

    character(1) input to BiocPkgTools::biocPkgList

-   vlist:

    list() if NULL, use biocPkgList to obtain current biocPkgList,
    otherwise a named list with outputs of previous calls to biocPkgList

</div>

<div class="section level2">

## Value

a data.frame with columns `pkg` and `view` for packages matching the
requested views

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
data("vlist", package="biocEDAM")
pksByViews(views = c("ChIPchip", "ShinyApps"), type="BioCsoft", vlist=vlist)
#>                          pkg      view
#> 1441           BiocHubsShiny ShinyApps
#> 2715            ChIPpeakAnno  ChIPchip
#> 2755              ChIPXpress  ChIPchip
#> 2786              ChromSCape ShinyApps
#> 2911                clevRvis ShinyApps
#> 4137         CytoPipelineGUI ShinyApps
#> 5873      ExploreModelMatrix ShinyApps
#> 6160              flowcatchR ShinyApps
#> 6670                     gDR ShinyApps
#> 6672                 gDRcore ShinyApps
#> 6897               GeneTonic ShinyApps
#> 7528                  GNOSIS ShinyApps
#> 8499                   iChip  ChIPchip
#> 8541                   ideal ShinyApps
#> 8823      interactiveDisplay ShinyApps
#> 8844  interactiveDisplayBase ShinyApps
#> 8974                    iSEE ShinyApps
#> 8990                 iSEEhub ShinyApps
#> 9006            iSEEpathways ShinyApps
#> 9384                     les  ChIPchip
#> 10015            MatrixQCvis ShinyApps
#> 10454                MetCirc ShinyApps
#> 11330             motifStack  ChIPchip
#> 11650           MSstatsShiny ShinyApps
#> 13047            pcaExplorer ShinyApps
#> 14960                 rGADEM  ChIPchip
#> 16018             scanMiRApp ShinyApps
#> 16814                 sevenC  ChIPchip
#> 18258        systemPipeShiny ShinyApps
#> 19054                   TSAR ShinyApps
```

</div>

</div>

</div>
