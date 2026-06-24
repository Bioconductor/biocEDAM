<div id="main" class="col-md-9" role="main">

# biocEDAM: ontology for a genomic data science ecosystem

<div class="section level2">

## Introduction

<div class="section level3">

### biocViews

The [biocViews](https://bioconductor.org/packages/biocViews) package
collects and organizes terms for tagging resources in the Bioconductor
ecosystem for genomic data science. As of November 2023 there are 497
terms defining classes of resources in the project. Example terms are
“Organism”, “BiologicalQuestion”, “Sequencing”, “MicroarrayData”.
Contributors and core members assign tags from this vocabulary to
software packages, data resources, and workflows that are managed and
distributed by the project.

[BiocPkgTools](https://bioconductor.org/package/BiocPkgTools) is a
package managing functions that interrogate aspects of the ecosystem. We
obtain a table of all software packages and examine the views:

<div id="cb1" class="sourceCode">

``` r
library(BiocPkgTools)
bl = biocPkgList(repo="BioCsoft")
library(dplyr)
s1 = bl |> select(Package, biocViews)
s1$tags = sapply(s1$biocViews, paste, collapse=":")
s1 = s1 |> select(Package, tags)
set.seed(1234)
s1[sample(seq_len(nrow(s1)), 10),]
```

</div>

    ## # A tibble: 10 × 2
    ##    Package        tags                                                          
    ##    <chr>          <chr>                                                         
    ##  1 HiLDA          Software:BiologicalQuestion:Technology:StatisticalMethod:Soma…
    ##  2 doseR          Software:Infrastructure:Technology:AssayDomain:ResearchField:…
    ##  3 graph          Software:StatisticalMethod:GraphAndNetwork                    
    ##  4 cn.farms       Software:Technology:AssayDomain:Microarray:CopyNumberVariation
    ##  5 sSeq           Software:ResearchField:Immunology:Technology:Sequencing:Immun…
    ##  6 plotgardener   Software:WorkflowStep:BiologicalQuestion:ResearchField:Techno…
    ##  7 yamss          Software:Technology:ResearchField:BiologicalQuestion:MassSpec…
    ##  8 iSEEpathways   Software:BiologicalQuestion:AssayDomain:Infrastructure:Workfl…
    ##  9 CAFE           Software:AssayDomain:Technology:Microarray:BiologicalQuestion…
    ## 10 tidyexposomics Software:ResearchField:AssayDomain:BiologicalQuestion:Workflo…

</div>

<div class="section level3">

### EDAM

At edamontology.org, EDAM is described as “a comprehensive ontology of
well-established, familiar concepts that are prevalent within
bioscientific data analysis and data management (including computational
biology, bioinformatics, and bioimage informatics). EDAM includes
topics, operations, types of data and data identifiers, and data
formats, relevant in data analysis and data management in life
sciences.”

With a devel version of ontoProc, we ingest and sample from the EDAM
ontology:

<div id="cb3" class="sourceCode">

``` r
library(ontoProc)
```

</div>

    ## Warning: multiple methods tables found for 'scale'

    ## Warning: replacing previous import 'BiocGenerics::scale' by
    ## 'DelayedArray::scale' when loading 'SummarizedExperiment'

<div id="cb6" class="sourceCode">

``` r
epath = owl2cache(url="https://edamontology.org/EDAM_1.25.owl")
edam = setup_entities2(epath)
set.seed(1234)
sam = sample(edam$name, 15)
edam = names(sam)
phr = as.character(sam)
DT::datatable(data.frame(edam,phr))
```

</div>

<div id="htmlwidget-ac96cb3ee4656e2e9ec3"
class="datatables html-widget html-fill-item"
style="width:100%;height:auto;">

</div>

The main organizing categories in EDAM are “data”, “format”, “operation”
and “topic”.

</div>

</div>

<div class="section level2">

## A preliminary comparison of the vocabularies

The Pypi package [text2term](https://pypi.org/project/text2term/) was
used to measure similarity between terms available in EDAM and terms of
biocViews. The [biocEDAM package](https://github.com/vjcitn/biocEDAM)
includes a table of results, that we filter here for scores exceeding
0.8.

<div id="cb7" class="sourceCode">

``` r
library(biocEDAM)
data(allmap)
ndf = allmap |> filter(`Mapping Score`>.8) |> select(`Source Term`, 
              `Mapped Term Label`, `Mapping Score`) |> as.data.frame()
library(DT)
datatable(ndf)
```

</div>

<div id="htmlwidget-e5c8c404fe174e4c81bd"
class="datatables html-widget html-fill-item"
style="width:100%;height:auto;">

</div>

Similar programming can be used to examine biocViews terms with low
maximum scores when matched against EDAM. These could indicate
vocabulary gaps to be filled in EDAM, or could suggest alternative
tagging methodology.

For example, biocViews includes “ExomeSeq”. This achieved scores of .70,
.50, .39 for EDAM terms Exome sequencing, Exome assembly, and “geneseq”
respectively. There are 9 software packages in Bioconductor 3.18
annotated to ExomeSeq. Dissection of their contents and additional views
terms will be helpful for understanding the process needed to bridge
EDAM to Bioconductor for improved discoverability of packages and data.

</div>

</div>
