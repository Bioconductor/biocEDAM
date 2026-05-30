#' utility to "clean" odd characters in text input that seem to increase risk of LLM failures
#' @param x character(1) text from which non-alphabetic characters like brackets and parentheses
#' are to be removed
#' @note This is speculative; success rates appear to increase with no evident degradation of
#' content interpretation.
#' @examples
#' cleantxt("RNA-seq (paired-end): analysis of #reads [v2]")
#' @export
cleantxt = function(x) gsub('-|\\(|`|#|:|\\*|’|"|\\[|\\]|\\$|\\{|\\}|=|\\(|\\||")', "", x)

#' simple utility to process output of edamize into a data.frame
#' @import rjsoncons
#' @rawNamespace import(jsonlite, except=validate)
#' @param x a data.frame as produced by edamize (returned as-is), or a legacy list
#' @note dplyr::distinct is run on the result
#' @examples
#' df <- data.frame(uri = "http://edamontology.org/topic_3308",
#'                  tm  = "Transcriptomics", stringsAsFactors = FALSE)
#' mkdf(df)  # data.frame input is passed through unchanged
#' @export
mkdf = function(x) {
    if (is.data.frame(x)) return(dplyr::distinct(x))
    lkj = jsonlite::toJSON(x)
    uri = fromJSON(rjsoncons::j_query(lkj, "$..uri"))
    tm  = fromJSON(rjsoncons::j_query(lkj, "$..term"))
    data.frame(uri, tm) |> dplyr::distinct()
}

# The four EDAM branch roots — too generic to tag anything with.
.EDAM_ROOTS = c("EDAM:topic_0003", "EDAM:operation_0004",
                "EDAM:data_0006",  "EDAM:format_1915")

# Internal: query the four EDAM term types from a SemanticSQL DBI connection.
# Returns a named list of data frames (topic, operation, data, format),
# each with columns id (CURIE) and lbl (label), excluding deprecated terms
# and the four branch-root nodes.
.get_edam_terms_from_db = function(con) {
    root_sql = paste0("'", .EDAM_ROOTS, "'", collapse = ", ")
    types = c("topic", "operation", "data", "format")
    lapply(setNames(types, types), function(type) {
        DBI::dbGetQuery(con, sprintf(
            "SELECT s.subject AS id, s.value AS lbl
             FROM rdfs_label_statement s
             WHERE s.subject LIKE 'EDAM:%s_%%'
               AND s.subject NOT IN (
                   SELECT subject FROM edge
                   WHERE object = 'owl:DeprecatedClass'
               )
               AND s.subject NOT IN (%s)",
            type, root_sql
        ))
    })
}

#' Assign EDAM ontology terms to text using a live SemanticSQL database and an LLM
#' @import dplyr ellmer btw
#' @importFrom DBI dbGetQuery
#' @param content_for_edam character(1) text describing a bioinformatics resource
#' @param provider character(1) LLM provider; see \code{\link{llm_env_var}}.
#' Defaults to "anthropic".
#' @param model character(1) model identifier for the selected provider.
#' Defaults to "claude-sonnet-4-5".
#' @param nterms integer(1) approximate number of EDAM terms to select. Defaults to 20.
#' @param prescrub logical(1) if TRUE apply \code{\link{cleantxt}} before processing.
#' Defaults to TRUE.
#' @param retrieve_k integer(1) or NULL.  When not NULL, use embedding-based
#' retrieval (via \code{\link{retrieve_edam_candidates}}) to pre-filter the
#' EDAM vocabulary to the top \code{retrieve_k} candidates per type before
#' LLM selection.  Requires \code{OPENAI_API_KEY} and the pre-computed
#' embedding artifact (see \code{\link{get_edam_embeddings}}).
#' Set to \code{NULL} to pass the full vocabulary directly to the LLM.
#' Defaults to 75L.
#' @param embed_model character(1) OpenAI embedding model used for retrieval;
#' must match the model used to build the artifact.
#' Defaults to \code{"text-embedding-3-small"}.
#' @param \dots passed to \code{\link{llm_chat}}
#' @return a data.frame with columns \code{uri} (full EDAM URI) and \code{tm} (term label),
#' restricted to confirmed vocabulary entries and deduplicated.  Compatible with
#' \code{\link{mkdf}}, \code{\link{toline}}, and \code{\link{edam_graph}}.
#' @note This function replaces the former Python/curbioc.py implementation.
#' It connects to the current EDAM release via \code{ontoProc2::semsql_connect()} and
#' selects terms using \code{chat_structured()} via ellmer, so no JSON schema validation
#' loop is needed and hallucinated term labels are eliminated by post-filtering against
#' the actual vocabulary.
#' @examples
#' # Input validation fires without any API key
#' tryCatch(edamize(list(a=1)), error = function(e) conditionMessage(e))
#'
#' if (interactive() &&
#'     nchar(Sys.getenv("ANTHROPIC_API_KEY")) > 0 &&
#'     nchar(Sys.getenv("OPENAI_API_KEY")) > 0) {
#'   content <- readRDS(system.file("rds/tximetaFocused.rds", package="biocEDAM"))
#'   lk <- edamize(content$focused)   # retrieve_k=75 uses bundled embeddings
#'   print(lk)
#'   # Skip embedding retrieval and pass full vocabulary to the LLM:
#'   lk2 <- edamize(content$focused, retrieve_k = NULL)
#'   print(lk2)
#' }
#' @export
edamize = function(
        content_for_edam,
        provider    = "anthropic",
        model       = "claude-sonnet-4-5",
        nterms      = 20L,
        prescrub    = TRUE,
        retrieve_k  = 75L,
        embed_model = "text-embedding-3-small",
        ...) {
    if (!is.character(content_for_edam) || length(content_for_edam) != 1L)
        stop("content_for_edam must be a single character string; ",
             "did you mean to pass e.g. tst$focused?")

    if (prescrub) content_for_edam = cleantxt(content_for_edam)

    if (!is.null(retrieve_k)) {
        edam_emb = get_edam_embeddings()
        edam_db  = retrieve_edam_candidates(content_for_edam, edam_emb,
                                             retrieve_k, embed_model)
    } else {
        ee      = ontoProc2::semsql_connect(ontology = "edam")
        edam_db = .get_edam_terms_from_db(ee@con)
    }

    ch = llm_chat(provider = provider, model = model, ...)

    sel_type = ellmer::type_array(
        ellmer::type_object(
            id  = ellmer::type_string(
                      description = "EDAM CURIE exactly as provided, e.g. EDAM:topic_0003"),
            lbl = ellmer::type_string(
                      description = "EDAM term label exactly as provided")
        )
    )

    prompt = paste0(
        "You are an expert bioinformatics curator. ",
        "Select approximately ", nterms, " EDAM ontology terms most relevant to the content below. ",
        "Aim for a balanced mix of topics, operations, data types, and formats. ",
        "Prefer specific, informative terms over generic parent categories ",
        "(e.g. avoid 'Bioinformatics' or 'Data analysis' unless uniquely fitting). ",
        "Return the id field EXACTLY as it appears in the vocabulary tables — ",
        "do not invent, paraphrase, or alter any id or label.\n\n",
        "CONTENT:\n", content_for_edam
    )

    result = ch$chat_structured(
        btw::btw(edam_db$topic, edam_db$operation, edam_db$data, edam_db$format, prompt),
        type = sel_type
    )

    # Discard any IDs not present in the actual vocabulary (hallucination guard)
    all_valid = do.call(rbind, edam_db)
    result    = result[result$id %in% all_valid$id, ]

    # Replace model-provided labels with authoritative database labels
    result$lbl = all_valid$lbl[match(result$id, all_valid$id)]

    # Convert CURIEs to full URIs and name columns to match legacy mkdf output
    data.frame(
        uri = sub("^EDAM:", "http://edamontology.org/", result$id),
        tm  = result$lbl,
        stringsAsFactors = FALSE
    ) |> dplyr::distinct()
}
