# make_edam_embeddings.R
# Maintainer script: generate the EDAM term embedding artifact for AnnotationHub.
#
# Prerequisites:
#   - OPENAI_API_KEY must be set
#   - biocEDAM and ontoProc2 installed
#
# Run once per EDAM release.  The resulting .rds is uploaded to the
# Bioconductor AnnotationHub S3 bucket as part of the submission process.
#
# Usage:
#   Rscript inst/scripts/make_edam_embeddings.R
# or interactively:
#   source("inst/scripts/make_edam_embeddings.R")

library(biocEDAM)

outfile <- file.path("inst", "extdata",
                     "edam_embeddings_openai_small.rds")
dir.create(dirname(outfile), showWarnings = FALSE, recursive = TRUE)

emb <- make_edam_embeddings(outfile = outfile,
                             model   = "text-embedding-3-small")

cat(sprintf(
    "Artifact: %s\n  Terms:      %d\n  Dimensions: %d\n  Model:      %s\n  Created:    %s\n",
    outfile,
    length(emb$ids),
    ncol(emb$embeddings),
    emb$model,
    format(emb$created)
))

# AnnotationHub metadata template (fill in and submit via AnnotationHubData)
# Title:       EDAM Ontology Term Embeddings (text-embedding-3-small)
# Description: Pre-computed OpenAI text-embedding-3-small embeddings for
#              non-deprecated EDAM ontology terms. Each term is represented
#              by its rdfs:label concatenated with its oio:hasDefinition text.
#              For use with biocEDAM::retrieve_edam_candidates() to pre-filter
#              the EDAM vocabulary before LLM-based term selection.
# SourceUrl:   http://edamontology.org/
# SourceType:  RDA
# DataProvider: biocEDAM
# RDataClass:  list
# DispatchClass: Rds
# Tags:        EDAM, ontology, embeddings, bioinformatics, RAG
