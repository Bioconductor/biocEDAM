# make_edam_embeddings_local.R
#
# Generate EDAM term embeddings using a local sentence-transformers model.
# No API key required. The chosen model is downloaded from HuggingFace on
# first use and cached in the HuggingFace hub cache (~200-500 MB).
#
# Usage:
#   Rscript inst/scripts/make_edam_embeddings_local.R
# or interactively:
#   source("inst/scripts/make_edam_embeddings_local.R")
#
# The output replaces inst/demo_embedding/edam_embeddings.rds and can be
# loaded at runtime via get_edam_embeddings() without any API key.
# retrieve_edam_candidates() detects automatically that it should use
# the local model for query embedding.
#
# Recommended model choices:
#
#   "FremyCompany/BioLORD-2023-C"          (default)
#     Biomedical concept representation — best fit for ontology term labels
#     and definitions.  768 dimensions.
#
#   "allenai/specter2_base"
#     Scientific text; strong on abstract-length definitions.  768 dimensions.
#
#   "pritamdeka/S-PubMedBert-MS-MARCO"
#     PubMedBERT fine-tuned for sentence similarity.  768 dimensions.
#
#   "sentence-transformers/all-mpnet-base-v2"
#     General-purpose high-quality model; good baseline.  768 dimensions.

library(biocEDAM)
library(reticulate)

MODEL   <- "FremyCompany/BioLORD-2023-C"
# Write to a location of your choosing; do NOT overwrite inst/demo_embedding.
# Set EDAM_EMBEDDING_RDS to this path to use the new artifact at runtime.
OUTFILE <- file.path(tempdir(), "edam_embeddings_bioLORD.rds")
BATCH_SIZE <- 32L

# ---- Python setup -----------------------------------------------------------

reticulate::py_require("sentence-transformers")
st <- reticulate::import("sentence_transformers")

# ---- Load model (downloads on first use, cached thereafter) -----------------

message("Loading model: ", MODEL, " ...")
encoder <- st$SentenceTransformer(MODEL)
message("Model loaded.")

# ---- Fetch EDAM terms with definitions from SemanticSQL ---------------------

ee    <- ontoProc2::semsql_connect(ontology = "edam")
terms <- biocEDAM:::.get_edam_terms_with_definitions(ee@con)
message(sprintf("Retrieved %d EDAM terms.", nrow(terms)))

# ---- Embed ------------------------------------------------------------------

message(sprintf("Embedding with batch_size=%d ...", BATCH_SIZE))
py_embs <- encoder$encode(
    as.list(terms$embed_text),
    batch_size       = BATCH_SIZE,
    show_progress_bar = TRUE,
    convert_to_numpy  = TRUE
)
emb_matrix <- reticulate::py_to_r(py_embs)
message(sprintf("Done: %d x %d matrix.", nrow(emb_matrix), ncol(emb_matrix)))

# ---- Save -------------------------------------------------------------------

result <- list(
    ids        = terms$id,
    labels     = terms$lbl,
    types      = terms$type,
    texts      = terms$embed_text,
    embeddings = emb_matrix,
    model      = MODEL,
    provider   = "local",     # retrieve_edam_candidates() routes query
    created    = Sys.time()   # embedding through sentence_transformers
)

dir.create(dirname(OUTFILE), showWarnings = FALSE, recursive = TRUE)
saveRDS(result, OUTFILE)

message(sprintf(
    "Artifact written to %s\n  Terms: %d | Dimensions: %d | Model: %s",
    OUTFILE, length(result$ids), ncol(emb_matrix), MODEL
))
