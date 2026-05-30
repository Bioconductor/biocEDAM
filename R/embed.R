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

#' Generate and save EDAM term embeddings using the OpenAI API
#'
#' Connects to the current EDAM SemanticSQL release, fetches term labels and
#' definitions, embeds them with OpenAI \code{text-embedding-3-small}, and
#' saves the result to \code{outfile}.  The saved object can be submitted to
#' AnnotationHub or loaded directly and passed to
#' \code{\link{retrieve_edam_candidates}}.
#'
#' Requires \code{OPENAI_API_KEY} to be set.
#'
#' @param outfile character(1) path for the output \code{.rds} file.
#' Defaults to \code{edam_embeddings.rds} in \code{tempdir()}.
#' @param model character(1) OpenAI embedding model.
#' Defaults to \code{"text-embedding-3-small"}.
#' @return invisibly, the embedding list (same structure as the AnnotationHub
#' resource returned by \code{\link{get_edam_embeddings}}).
#' @export
make_edam_embeddings <- function(
        outfile = file.path(tempdir(), "edam_embeddings.rds"),
        model   = "text-embedding-3-small") {
    api_key <- llm_api_key("openai")
    ee      <- ontoProc2::semsql_connect(ontology = "edam")
    terms   <- .get_edam_terms_with_definitions(ee@con)
    message(sprintf("Embedding %d EDAM terms via OpenAI (%s)...",
                    nrow(terms), model))
    embs <- .embed_openai(terms$embed_text, api_key, model)
    result <- list(
        ids        = terms$id,
        labels     = terms$lbl,
        types      = terms$type,
        texts      = terms$embed_text,
        embeddings = embs,
        model      = model,
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
#' @export
retrieve_edam_candidates <- function(content, edam_emb,
                                     retrieve_k   = 75L,
                                     embed_model  = "text-embedding-3-small") {
    if (edam_emb$model != embed_model)
        stop(sprintf(
            "embed_model '%s' does not match the artifact model '%s'.\n",
            embed_model, edam_emb$model),
            sprintf(
            "Run make_edam_embeddings(model = '%s') to generate a matching artifact.",
            embed_model))
    api_key <- llm_api_key("openai")
    q_emb   <- .embed_openai(content, api_key, embed_model)[1L, ]
    sims    <- .cosine_sim(q_emb, edam_emb$embeddings)

    types <- c("topic", "operation", "data", "format")
    lapply(setNames(types, types), function(type) {
        idx      <- which(edam_emb$types == type)
        top_idx  <- idx[order(sims[idx], decreasing = TRUE)[
                            seq_len(min(retrieve_k, length(idx)))]]
        data.frame(id  = edam_emb$ids[top_idx],
                   lbl = edam_emb$labels[top_idx],
                   stringsAsFactors = FALSE)
    })
}
