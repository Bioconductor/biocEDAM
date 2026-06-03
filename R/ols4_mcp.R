#' List tools available from the EBI OLS4 MCP service
#'
#' Connects to the EBI OLS4 Ontology Lookup Service MCP endpoint using
#' \code{mcp-remote} as a local stdio-to-Streamable-HTTP bridge, and returns
#' the available tools as ellmer tool objects ready for use in an LLM chat.
#'
#' @param url character(1) URL of the EBI OLS4 MCP endpoint.
#' Defaults to \code{"https://www.ebi.ac.uk/ols4/api/mcp"}.
#' @return a named list of ellmer \code{ToolDef} objects, one per tool exposed
#' by the service.  Pass directly to an ellmer chat's tool registration, or
#' summarise with \code{\link{ols4_tool_table}}.
#' @note Requires \code{npx} and \code{mcp-remote} on the system PATH.
#' Install the bridge once with:
#' \preformatted{npm install -g mcp-remote}
#' The bridge translates stdio MCP (which mcptools speaks) into the
#' Streamable HTTP transport used by the EBI OLS4 endpoint.
#' @examples
#' if (interactive()) {
#'     tools <- ols4_mcp_tools()
#'     ols4_tool_table(tools)
#' }
#' @export
ols4_mcp_tools <- function(url = "https://www.ebi.ac.uk/ols4/api/mcp") {
    cfg <- list(
        mcpServers = list(
            ols4 = list(
                command = "npx",
                args    = list("mcp-remote", url)
            )
        )
    )
    tmp <- tempfile(fileext = ".json")
    on.exit(unlink(tmp), add = TRUE)
    writeLines(
        jsonlite::toJSON(cfg, auto_unbox = TRUE, pretty = TRUE),
        tmp
    )
    mcptools::mcp_tools(config = tmp)
}

#' Create an ellmer chat pre-wired with EBI OLS4 MCP tools
#'
#' Calls \code{\link{ols4_mcp_tools}} to retrieve the 12 OLS4 search tools,
#' creates an ellmer chat object via \code{\link{llm_chat}}, and registers all
#' tools on the chat so the LLM can invoke them during structured calls.
#'
#' @param provider character(1) LLM provider; see \code{\link{llm_env_var}}.
#' Defaults to \code{"anthropic"}.
#' @param model character(1) model identifier. Defaults to
#' \code{"claude-sonnet-4-5"}.
#' @param temperature numeric(1) sampling temperature passed to the LLM.
#' Defaults to \code{0} for deterministic, reproducible output.
#' @param url character(1) OLS4 MCP endpoint URL passed to
#' \code{\link{ols4_mcp_tools}}.
#' @param \dots additional arguments passed to \code{\link{llm_chat}}.
#' @return an ellmer \code{Chat} object with all OLS4 tools registered.
#' @note Starting the \code{mcp-remote} bridge takes a few seconds.
#' Reuse the returned object across multiple calls rather than creating
#' a new one each time.
#' @examples
#' if (interactive()) {
#'     ch <- ols4_chat()
#'     map_concepts("chromatin accessibility and histone modification", chat = ch)
#' }
#' @export
ols4_chat <- function(provider    = "anthropic",
                      model       = "claude-sonnet-4-5",
                      temperature = 0,
                      url         = "https://www.ebi.ac.uk/ols4/api/mcp",
                      ...) {
    tools <- ols4_mcp_tools(url = url)
    chat  <- llm_chat(provider = provider, model = model,
                      api_args = list(temperature = temperature), ...)
    chat$register_tools(tools)
    chat
}

# Check whether an LLM-generated label and an OLS4 canonical label refer to
# the same concept by looking for shared content words.  Returns NA when either
# label is missing.
.labels_match <- function(llm_label, ols4_label) {
    if (is.na(llm_label) || is.na(ols4_label)) return(NA)
    stopwords <- c("a", "an", "the", "of", "for", "and", "or", "in", "to",
                   "with", "by", "from", "on", "at", "as", "its", "is")
    words <- function(s) {
        w <- tolower(strsplit(s, "[^a-z]+")[[1L]])
        w[nchar(w) > 2L & !w %in% stopwords]
    }
    lw <- words(llm_label)
    ow <- words(ols4_label)
    if (length(lw) == 0L || length(ow) == 0L) return(NA)
    length(intersect(lw, ow)) > 0L
}

# Look up a single term IRI against the OLS4 REST API.
# Returns NULL if the term is not found, otherwise a list with
# label and definition (character, possibly NA).
.ols4_lookup_iri <- function(iri) {
    resp <- tryCatch(
        httr2::request("https://www.ebi.ac.uk/ols4/api/terms") |>
            httr2::req_url_query(iri = iri) |>
            httr2::req_throttle(rate = 5) |>
            httr2::req_retry(max_tries = 3L,
                             is_transient = \(r) httr2::resp_status(r) == 429L) |>
            httr2::req_error(is_error = function(r) FALSE) |>
            httr2::req_perform() |>
            httr2::resp_body_json(),
        error = function(e) NULL
    )
    if (is.null(resp)) return(NULL)
    terms <- resp[["_embedded"]][["terms"]]
    if (is.null(terms) || length(terms) == 0L) return(NULL)
    term <- terms[[1L]]
    desc <- term[["description"]]
    list(
        label      = term[["label"]] %||% NA_character_,
        definition = if (!is.null(desc) && length(desc) > 0L)
                         as.character(desc[[1L]])
                     else
                         NA_character_
    )
}

#' Validate and enrich a TermMappingTable via the OLS4 REST API
#'
#' For each row in \code{result}, queries the EBI OLS4 REST API by
#' \code{term_iri} to confirm the term exists and retrieve an authoritative
#' definition.  All rows are retained; two columns are added:
#' \describe{
#'   \item{validated}{logical — \code{TRUE} if the IRI was found in OLS4,
#'     \code{FALSE} if not (possible hallucination or deprecated term)}
#'   \item{definition}{character — the OLS4-sourced definition for validated
#'     terms; \code{NA} for unvalidated rows}
#' }
#'
#' Three columns are added or updated:
#' \describe{
#'   \item{llm_label}{The original label as produced by the LLM, preserved
#'     before being replaced by the OLS4 canonical label}
#'   \item{label_match}{logical — \code{TRUE} if the LLM label and the OLS4
#'     canonical label share at least one content word (a basic semantic
#'     consistency check); \code{FALSE} flags cases where the LLM supplied a
#'     real but unrelated IRI (e.g. "variant calling" → "Cystatin-SN");
#'     \code{NA} for unvalidated rows}
#'   \item{definition}{OLS4-sourced definition; \code{NA} for unvalidated rows}
#' }
#' Rows where \code{validated = TRUE} but \code{label_match = FALSE} are the
#' most suspicious: the IRI exists in OLS4 but likely does not correspond to
#' the extracted concept.
#'
#' @param result data.frame as returned by \code{\link{map_concepts}}.
#' @param label_match logical(1) if \code{TRUE}, add \code{llm_label} and
#' \code{label_match} columns (content-word overlap check between the LLM label
#' and the OLS4 canonical label).  Defaults to \code{FALSE}.
#' @return \code{result} with \code{validated} and \code{definition} columns
#' added, and optionally \code{llm_label} and \code{label_match}.
#' @examples
#' if (interactive()) {
#'     ch  <- ols4_chat()
#'     raw <- map_concepts("atrial fibrillation and genome sequencing", chat = ch)
#'     enr <- ols4_enrich(raw)
#'     enr[enr$validated, ]   # confirmed terms only
#' }
#' @export
ols4_enrich <- function(result, label_match = FALSE) {
    if (nrow(result) == 0L) {
        result$validated  <- logical(0L)
        result$definition <- character(0L)
        return(result)
    }
    message(sprintf("Validating %d term IRI(s) against OLS4 REST API...",
                    nrow(result)))
    lookups <- lapply(result$term_iri, .ols4_lookup_iri)
    found   <- vapply(lookups, Negate(is.null), logical(1L))

    if (any(!found))
        message(sprintf(
            "%d term(s) not confirmed in OLS4 (validated = FALSE): %s",
            sum(!found),
            paste(result$term_iri[!found], collapse = ", ")
        ))

    canonical <- vapply(lookups, function(x) {
        if (is.null(x)) NA_character_ else x$label %||% NA_character_
    }, character(1L))

    # Replace LLM label with canonical OLS4 label where available
    has_canonical <- !is.na(canonical)
    if (label_match) {
        result$llm_label <- result$term_label
        result$term_label[has_canonical] <- canonical[has_canonical]
        result$label_match <- mapply(.labels_match,
                                     result$llm_label, result$term_label)
    } else {
        result$term_label[has_canonical] <- canonical[has_canonical]
    }

    result$validated  <- found
    result$definition <- vapply(
        lookups,
        function(x) if (is.null(x)) NA_character_ else x$definition %||% NA_character_,
        character(1L)
    )
    result
}

#' Map biological or medical concepts to ontology terms via OLS4
#'
#' Sends \code{query} to an ellmer chat that has EBI OLS4 search tools
#' registered, asking the LLM to identify concepts and retrieve the best
#' matching ontology terms.  Returns a typed data frame conforming to
#' \code{\link{TermMappingTable}}.
#'
#' Each row is validated against the EBI OLS4 REST API via
#' \code{\link{ols4_enrich}}: rows whose \code{term_iri} cannot be found in
#' OLS4 are dropped with a warning, and an authoritative \code{definition}
#' column is added alongside the LLM-generated \code{rationale}.
#'
#' @param query character(1) free-text input containing one or more biological
#' or medical concepts.
#' @param provider character(1) LLM provider; see \code{\link{llm_env_var}}.
#' Defaults to \code{"anthropic"}.
#' @param model character(1) model identifier for the chosen provider.
#' Defaults to \code{"claude-sonnet-4-5"}.
#' @param temperature numeric(1) sampling temperature; defaults to \code{0}
#' for deterministic output.  Ignored when \code{chat} is supplied directly.
#' @param prompt character(1) instruction text sent to the LLM before the
#' input text.  Defaults to the contents of
#' \code{inst/prompts/map_concepts.txt}; use
#' \code{\link{read_prompt}("map_concepts.txt")} to inspect or customise.
#' @param label_match logical(1) if \code{TRUE}, adds \code{llm_label} and
#' \code{label_match} columns via \code{\link{ols4_enrich}}, flagging rows
#' where the LLM label and OLS4 canonical label share no content words
#' (a sign of a hallucinated IRI).  Defaults to \code{FALSE}.
#' @param chat an ellmer \code{Chat} object with OLS4 tools already registered.
#' When supplied, \code{provider}, \code{model}, and \code{temperature} are
#' ignored.  Build once with \code{\link{ols4_chat}} and reuse across calls to
#' avoid restarting the bridge process each time.
#' @return a data.frame with columns \code{input_text}, \code{term_label},
#' \code{term_iri}, \code{obo_id}, \code{ontology}, \code{rationale},
#' \code{validated}, and \code{definition}, one row per concept-term pair
#' (plus \code{llm_label} and \code{label_match} when \code{label_match=TRUE}).
#' Filter on \code{validated == TRUE} to retain only OLS4-confirmed terms.
#' @examples
#' if (interactive()) {
#'     # default provider (anthropic)
#'     map_concepts("spatial autocorrelation in gene expression")
#'
#'     # switch provider
#'     map_concepts("chromatin accessibility",
#'                  provider = "openai", model = "gpt-4o")
#'
#'     # reuse a pre-built chat across multiple calls
#'     ch <- ols4_chat()
#'     map_concepts("atrial fibrillation", chat = ch)
#'     map_concepts("whole genome sequencing", chat = ch)
#' }
#' @export
map_concepts <- function(query,
                         provider    = "anthropic",
                         model       = "claude-sonnet-4-5",
                         temperature = 0,
                         prompt      = read_prompt("map_concepts.txt"),
                         label_match = FALSE,
                         chat        = ols4_chat(provider    = provider,
                                                  model       = model,
                                                  temperature = temperature)) {
    result <- chat$chat_structured(
        paste0(prompt, "\n\nInput text: ", query),
        type = TermMappingTable
    )
    ols4_enrich(result, label_match = label_match)
}

#' Export a map_concepts result as a JSON document
#'
#' Converts the data.frame returned by \code{\link{map_concepts}} into a JSON
#' document.  Terms are grouped by ontology; each entry records the ontology
#' IRI, term label, OBO identifier, and the input concept that was mapped.
#'
#' @rawNamespace import(jsonlite, except=validate)
#' @param x data.frame as returned by \code{\link{map_concepts}}.
#' @param validated_only logical(1) if \code{TRUE} (default), only rows where
#'   \code{validated == TRUE} are included.
#' @param path character(1) or \code{NULL}.  When not \code{NULL}, the JSON is
#'   written to this file path and \code{NULL} is returned invisibly.  When
#'   \code{NULL} (default) the JSON string is returned.
#' @return A JSON character string, or \code{NULL} invisibly when \code{path}
#'   is supplied.
#' @examples
#' df <- data.frame(
#'   input_text = c("atrial fibrillation", "genome sequencing"),
#'   term_label = c("Atrial Fibrillation", "Whole Genome Sequencing"),
#'   term_iri   = c("http://purl.obolibrary.org/obo/HP_0005110",
#'                  "http://purl.obolibrary.org/obo/OBI_0002117"),
#'   obo_id     = c("HP:0005110", "OBI:0002117"),
#'   ontology   = c("HP", "OBI"),
#'   rationale  = c("matches concept", "matches concept"),
#'   validated  = c(TRUE, TRUE),
#'   definition = c(NA_character_, NA_character_),
#'   stringsAsFactors = FALSE
#' )
#' cat(mapping_to_json(df))
#' @export
mapping_to_json <- function(x, validated_only = TRUE, path = NULL) {
    if (validated_only && "validated" %in% names(x))
        x <- x[x$validated, ]
    keep    <- intersect(c("input_text", "term_label", "term_iri", "obo_id"),
                         names(x))
    grouped <- split(x[, keep, drop = FALSE], x$ontology)
    grouped <- lapply(grouped, function(df) { rownames(df) <- NULL; df })
    json    <- jsonlite::toJSON(grouped, pretty = TRUE, auto_unbox = TRUE)
    if (!is.null(path)) {
        writeLines(json, path)
        return(invisible(NULL))
    }
    json
}

#' Summarise OLS4 MCP tools as a data frame
#'
#' @param tools list of ellmer tool objects as returned by
#' \code{\link{ols4_mcp_tools}}.
#' @return a data.frame with columns \code{name} and \code{description},
#' one row per tool.
#' @examples
#' if (interactive()) {
#'     tools <- ols4_mcp_tools()
#'     ols4_tool_table(tools)
#' }
#' @export
ols4_tool_table <- function(tools) {
    data.frame(
        name        = vapply(tools, function(t) t@name,        character(1L)),
        description = vapply(tools, function(t) t@description, character(1L)),
        stringsAsFactors = FALSE
    )
}
