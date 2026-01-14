# biocEDAM

This package investigates tools that
can help understand the relationship
of [biocViews](https://bioconductor.org/packages/biocViews) in relation to the 
[EDAM ontology](https://edamontology.org). A brief introduction to EDAM Ontology is also reported in this [Bioconductor post](https://blog.bioconductor.org/posts/2025-07-18-edam/)

## Installation 


- Use `BiocManager::install('vjcitn/biocEDAM')` to install this package.

- The DESCRIPTION file of the package defines python requirements.

- When functions requiring python are called, a virtual environment
will be created by reticulate to resolve references to modules in use.

Note that some functions require that a valid OpenAI API key is
readable through the environment variable `OPENAI_API_KEY`.  When
this is absent, functions will simply fail.

Charges to the associated OpenAI account will accrue when these functions
are called.  All the experimental work underlying the development of the
code in March 2025 produced charges of $1.34.  You can examine your
charges at `platform.openai.com/usage`.

## Purpose

[biocViews](https://bioconductor.org/packages/biocViews) is an ad hoc vocabulary in
the form of a graphNEL instance with over 400 terms.  [EDAM](https://edamontology.org)
is an OWL model of a vocabulary devoted to concepts of data analysis and data management
in the biosciences.  This package unites these two resources with the objective of
permitting exploration that will lead to formal ontological tagging of all Bioconductor
software and data packages and workflows.

## Tools

### vig2data

This function uses rvest, pdftools, and gpt-4o via ellmer to transform content (typically
referenced via URL for Bioconductor vignettes, see examples) to structured
data about authors, topics (determined _ad libitum_ by GPT), and a component
`focused` which is a concise summary of content up to 450 words.  This component
will be used in `edamize`.

### edamize

This function calls python code of Anh Nguyet Vu that prompts GPT to
select and organize terms from EDAM on the basis of relevance to the
supplied text (`focused` from `vig2data` in the intended application).
Terms from the topic, operation, data, and format components of EDAM
may be returned.

### bvbrowse

This function starts a shiny app that presents term-filtered sets of packages
and their views annotation.

![](https://github.com/vjcitn/biocEDAM/blob/main/BrowseGeneSig.png?raw=true)

### allmap

The `allmap` data.frame is the output of [text2term](https://pypi.org/text2term)
applied to biocViews terms for evaluation of similarity to terms
in the EDAM ontology.

```
> head(allmap)
                              Source Term ID    Source Term
0 http://ccb.hms.harvard.edu/t2t/RFzhTje9ucG      BiocViews
1 http://ccb.hms.harvard.edu/t2t/RFzhTje9ucG      BiocViews
2 http://ccb.hms.harvard.edu/t2t/R3hqXkeJtkt       Software
3 http://ccb.hms.harvard.edu/t2t/R4dWXrwrX3W AnnotationData
4 http://ccb.hms.harvard.edu/t2t/R4dWXrwrX3W AnnotationData
5 http://ccb.hms.harvard.edu/t2t/R4dWXrwrX3W AnnotationData
     Mapped Term Label   Mapped Term CURIE
0     GenomeReviews ID      EDAM.DATA:2751
1                 BioC    EDAM.FORMAT:3782
2 Software engineering     EDAM.TOPIC:3372
3           Annotation      EDAM.DATA:2018
4           Annotation EDAM.OPERATION:0226
5          Gene report      EDAM.DATA:0916
                         Mapped Term IRI Mapping Score Tags
0      http://edamontology.org/data_2751         0.459 None
1    http://edamontology.org/format_3782         0.380 None
2     http://edamontology.org/topic_3372         0.721 None
3      http://edamontology.org/data_2018         0.805 None
4 http://edamontology.org/operation_0226         0.805 None
5      http://edamontology.org/data_0916         0.703 None
```
