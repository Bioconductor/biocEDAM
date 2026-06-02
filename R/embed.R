# ---- OpenAI embedding API (httr2) ------------------------------------------

# Batch-embed texts via OpenAI.  Splits into chunks of 500 to stay within
# the API's per-request limit.
.embed_openai <- function(texts, api_key,
                          model = "text-embedding-3-small") {
    batches <- split(texts, ceiling(seq_along(texts) / 500L))
    rows <- lapply(batches, function(batch) {
        resp <- httr2::request("https://api.openai.com/v1/embeddings") |>
            httr2::req_headers(Authorization = paste("Bearer", api_key)) |>
            httr2::req_body_json(list(model = model,
                                     input = as.list(batch))) |>
            httr2::req_perform() |>
            httr2::resp_body_json()
        do.call(rbind, lapply(resp$data,
                              function(x) unlist(x$embedding)))
    })
    do.call(rbind, rows)
}

# ---- HuggingFace Inference API embedding ------------------------------------

# Embed texts via the HuggingFace Serverless Inference API.
# Passes options=list(wait_for_model=TRUE) so cold-start 503s are handled
# server-side rather than requiring client retries.
# sentence-transformers models return pooled vectors; plain BERT models return
# token-level hidden states which are mean-pooled here.
.embed_huggingface <- function(texts, model, api_key) {
    url     <- paste0("https://api-inference.huggingface.co/models/", model)
    batches <- split(texts, ceiling(seq_along(texts) / 50L))
    rows <- lapply(batches, function(batch) {
        resp <- httr2::request(url) |>
            httr2::req_headers(Authorization = paste("Bearer", api_key)) |>
            httr2::req_body_json(list(inputs  = as.list(batch),
                                      options = list(wait_for_model = TRUE))) |>
            httr2::req_perform() |>
            httr2::resp_body_json()
        do.call(rbind, lapply(resp, function(x) {
            if (is.list(x[[1L]]))          # token-level → mean-pool
                colMeans(do.call(rbind, lapply(x, unlist)))
            else
                unlist(x)                  # already pooled
        }))
    })
    do.call(rbind, rows)
}

# ---- local sentence-transformers embedding ----------------------------------

# Embed texts using a local HuggingFace sentence-transformers model.
# The model is downloaded on first use and cached by HuggingFace.
.embed_local <- function(texts, model) {
    reticulate::py_require("sentence-transformers")
    st      <- reticulate::import("sentence_transformers")
    encoder <- st$SentenceTransformer(model)
    py_out  <- encoder$encode(as.list(texts),
                               batch_size        = 32L,
                               show_progress_bar = FALSE,
                               convert_to_numpy  = TRUE)
    reticulate::py_to_r(py_out)
}

# TRUE if model is an OpenAI API embedding model, FALSE for local HF models.
.is_openai_model <- function(model) {
    startsWith(model, "text-embedding-")
}

# ---- cosine similarity ------------------------------------------------------

.cosine_sim <- function(query, mat) {
    q_norm  <- sqrt(sum(query ^ 2))
    m_norms <- sqrt(rowSums(mat ^ 2))
    drop(mat %*% query) / (m_norms * q_norm)
}

# ---- EDAM term text (label + definition) ------------------------------------

# Fetches label + oio:hasDefinition for the four EDAM types, concatenates
# them into a single 'embed_text' column for richer embedding signal.
.get_edam_terms_with_definitions <- function(con) {
    types <- c("topic", "operation", "data", "format")
    root_sql <- paste0("'", .EDAM_ROOTS, "'", collapse = ", ")
    out <- lapply(setNames(types, types), function(type) {
        DBI::dbGetQuery(con, sprintf(
            "SELECT l.subject AS id, l.value AS lbl, d.value AS definition
             FROM rdfs_label_statement l
             LEFT JOIN (
               SELECT stanza, value FROM statements
               WHERE predicate = 'oio:hasDefinition' AND value IS NOT NULL
             ) d ON l.subject = d.stanza
             WHERE l.subject LIKE 'EDAM:%s_%%'
               AND l.subject NOT IN (
                 SELECT subject FROM edge
                 WHERE object = 'owl:DeprecatedClass'
               )
               AND l.subject NOT IN (%s)",
            type, root_sql
        ))
    })
    all_terms <- do.call(rbind, Map(
        function(df, type) { df$type <- type; df },
        out, names(out)
    ))
    all_terms$embed_text <- ifelse(
        is.na(all_terms$definition) | all_terms$definition == "",
        all_terms$lbl,
        paste0(all_terms$lbl, ": ", all_terms$definition)
    )
    all_terms
}

# ---- artifact retrieval -----------------------------------------------------

#' Retrieve pre-computed EDAM term embeddings from AnnotationHub
#'
#' Downloads (and caches locally via AnnotationHub) a matrix of
#' \code{text-embedding-3-small} embeddings for all non-deprecated EDAM terms.
#' Each term is represented by its label concatenated with its
#' \code{oio:hasDefinition} text.  On first call the file is downloaded;
#' subsequent calls in the same or future sessions use the local cache.
#'
#' Lookup order:
#' \enumerate{
#'   \item If \code{EDAM_EMBEDDING_RDS} is set to a readable \code{.rds} path,
#'         that file is loaded and returned immediately.
#'   \item The file bundled with the package at
#'         \code{inst/demo_embedding/edam_embeddings.rds} is used (via
#'         \code{system.file}).
#'   \item AnnotationHub is queried for a \code{biocEDAM} embedding resource.
#' }
#' To override the bundled demo file with a freshly generated artifact, set
#' \code{EDAM_EMBEDDING_RDS} to its path or ensure the resource is in
#' AnnotationHub (see \code{\link{make_edam_embeddings}}).
#'
#' @return a list with components \code{ids}, \code{labels}, \code{types},
#' \code{texts}, \code{embeddings} (numeric matrix, terms × dimensions),
#' \code{model}, and \code{created}.
#' @examples
#' emb <- get_edam_embeddings()
#' cat(sprintf("%d terms | %d dimensions | model: %s\n",
#'     length(emb$ids), ncol(emb$embeddings), emb$model))
#' @importFrom AnnotationHub AnnotationHub query
#' @export
get_edam_embeddings <- function() {
    # 1. Explicit env-var override
    env_path <- Sys.getenv("EDAM_EMBEDDING_RDS", unset = "")
    if (nchar(env_path) > 0L) {
        if (!file.exists(env_path))
            stop("EDAM_EMBEDDING_RDS is set to '", env_path,
                 "' but the file does not exist.")
        message("Loading EDAM embeddings from EDAM_EMBEDDING_RDS: ", env_path)
        return(readRDS(env_path))
    }
    # 2. Bundled demo embedding shipped with the package
    pkg_path <- system.file("demo_embedding", "edam_embeddings.rds",
                            package = "biocEDAM")
    if (nchar(pkg_path) > 0L) {
        message("Loading bundled EDAM embeddings from ", pkg_path)
        return(readRDS(pkg_path))
    }
    # 3. AnnotationHub
    hub <- AnnotationHub::AnnotationHub()
    q   <- AnnotationHub::query(
               hub, c("biocEDAM", "EDAM", "embeddings",
                      "text-embedding-3-small"))
    if (length(q) == 0L)
        stop("No EDAM embedding artifact found.\n",
             "Generate one with biocEDAM::make_edam_embeddings() and set ",
             "EDAM_EMBEDDING_RDS to its path.")
    q[[length(q)]]
}

# ---- artifact generation (maintainer / fallback) ----------------------------

#' Generate and save EDAM term embeddings
#'
#' Connects to the current EDAM SemanticSQL release, fetches term labels and
#' definitions, embeds them using the specified provider, and saves the result
#' to \code{outfile}.  The saved object can be submitted to AnnotationHub or
#' loaded directly via \code{\link{get_edam_embeddings}}.
#'
#' @param outfile character(1) path for the output \code{.rds} file.
#' Defaults to \code{edam_embeddings.rds} in \code{tempdir()}.
#' @param model character(1) embedding model identifier.
#' For \code{provider="openai"} use e.g. \code{"text-embedding-3-small"};
#' for \code{provider="huggingface"} use a HuggingFace model ID such as
#' \code{"FremyCompany/BioLORD-2023-C"}.
#' @param provider character(1) embedding provider: \code{"openai"} (default)
#' or \code{"huggingface"}.  The corresponding environment variable must be
#' set (see \code{\link{llm_env_var}}).
#' @return invisibly, the embedding list (same structure as the AnnotationHub
#' resource returned by \code{\link{get_edam_embeddings}}).
#' @examples
#' if (interactive() && nchar(Sys.getenv("OPENAI_API_KEY")) > 0) {
#'     out <- file.path(tempdir(), "edam_test.rds")
#'     emb <- make_edam_embeddings(outfile = out)
#'     cat("Terms embedded:", length(emb$ids), "\n")
#'     unlink(out)
#' }
#' @export
make_edam_embeddings <- function(
        outfile  = file.path(tempdir(), "edam_embeddings.rds"),
        model    = "text-embedding-3-small",
        provider = "openai") {
    api_key <- llm_api_key(provider)
    ee      <- ontoProc2::semsql_connect(ontology = "edam")
    terms   <- .get_edam_terms_with_definitions(ee@con)
    message(sprintf("Embedding %d EDAM terms via %s (%s)...",
                    nrow(terms), provider, model))
    embs <- switch(provider,
        openai      = .embed_openai(terms$embed_text, api_key, model),
        huggingface = .embed_huggingface(terms$embed_text, model, api_key),
        stop(sprintf("Unsupported embed provider: '%s'", provider))
    )
    result <- list(
        ids        = terms$id,
        labels     = terms$lbl,
        types      = terms$type,
        texts      = terms$embed_text,
        embeddings = embs,
        model      = model,
        provider   = provider,
        created    = Sys.time()
    )
    saveRDS(result, outfile)
    message("Saved to ", outfile)
    invisible(result)
}

# ---- candidate retrieval ----------------------------------------------------

#' Retrieve the top-k semantically closest EDAM terms per type
#'
#' Embeds \code{content} using the OpenAI API, computes cosine similarity
#' against a pre-computed EDAM embedding matrix, and returns the top
#' \code{retrieve_k} candidates per EDAM type (topic, operation, data, format).
#'
#' @param content character(1) text to use as the query (e.g. a package
#' description).
#' @param edam_emb list as returned by \code{\link{get_edam_embeddings}} or
#' \code{\link{make_edam_embeddings}}.
#' @param retrieve_k integer(1) number of candidates to keep per type.
#' @param embed_model character(1) OpenAI embedding model; must match the model
#' used to build \code{edam_emb}.  Defaults to \code{"text-embedding-3-small"}.
#' @return named list of data.frames (topic, operation, data, format), each
#' with columns \code{id} and \code{lbl}, ordered by descending cosine
#' similarity to \code{content}.
#' @examples
#' # Model mismatch is caught before any API call
#' emb <- get_edam_embeddings()
#' tryCatch(
#'     retrieve_edam_candidates("some text", emb,
#'                              embed_model = "text-embedding-3-large"),
#'     error = function(e) conditionMessage(e)
#' )
#'
#' if (interactive() && nchar(Sys.getenv("OPENAI_API_KEY")) > 0) {
#'     candidates <- retrieve_edam_candidates(
#'         "RNA-seq transcript quantification and metadata management",
#'         emb, retrieve_k = 5L)
#'     candidates$topic
#' }
#' @export
retrieve_edam_candidates <- function(content, edam_emb,
                                     retrieve_k    = 75L,
                                     sim_threshold = 0.3,
                                     embed_model   = edam_emb$model) {
    if (edam_emb$model != embed_model)
        stop(sprintf(
            "embed_model '%s' does not match the artifact model '%s'.\n",
            embed_model, edam_emb$model),
            sprintf(
            "Run make_edam_embeddings(model = '%s') to generate a matching artifact.",
            embed_model))
    # Determine provider: use stored field if present, else infer from model name
    provider <- edam_emb$provider %||%
        if (.is_openai_model(embed_model)) "openai" else "local"
    q_emb <- switch(provider,
        openai = {
            api_key <- llm_api_key("openai")
            .embed_openai(content, api_key, embed_model)[1L, ]
        },
        huggingface = {
            api_key <- llm_api_key("huggingface")
            .embed_huggingface(content, embed_model, api_key)[1L, ]
        },
        local = .embed_local(content, embed_model)[1L, ],
        stop(sprintf("Unknown embed provider '%s' in artifact.", provider))
    )
    sims <- .cosine_sim(q_emb, edam_emb$embeddings)

    types <- c("topic", "operation", "data", "format")
    lapply(setNames(types, types), function(type) {
        idx     <- which(edam_emb$types == type & sims >= sim_threshold)
        if (length(idx) == 0L)
            return(data.frame(id = character(), lbl = character(),
                              stringsAsFactors = FALSE))
        top_idx <- idx[order(sims[idx], decreasing = TRUE)[
                           seq_len(min(retrieve_k, length(idx)))]]
        data.frame(id  = edam_emb$ids[top_idx],
                   lbl = edam_emb$labels[top_idx],
                   stringsAsFactors = FALSE)
    })
}
