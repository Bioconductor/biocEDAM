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

# Parse LABEL / ONTOLOGY / RATIONALE from an LLM plain-text response.
# Returns NULL if no LABEL line is found.
.parse_label_response <- function(text) {
    lines <- trimws(strsplit(text, "\n")[[1L]])
    get_field <- function(key) {
        pat <- paste0("^", key, "\\s*:\\s*")
        m   <- grep(pat, lines, ignore.case = TRUE, value = TRUE)
        if (length(m) == 0L) return(NA_character_)
        trimws(sub(pat, "", m[[1L]], ignore.case = TRUE))
    }
    label     <- get_field("LABEL")
    if (is.na(label) || !nchar(label)) return(NULL)
    if (trimws(tolower(label)) == "none") return(NULL)
    list(label     = label,
         ontology  = get_field("ONTOLOGY"),
         rationale = get_field("RATIONALE") %||% "")
}

# Search OLS4 by label string via REST; falls back from exact to fuzzy match.
# Returns list(term_label, term_iri, obo_id, ontology) or NULL if not found.
.ols4_search_label <- function(label, ontology = NULL) {
    build_req <- function(exact) {
        req <- httr2::request("https://www.ebi.ac.uk/ols4/api/search") |>
            httr2::req_url_query(
                q           = label,
                queryFields = "label",
                fieldList   = "iri,label,obo_id,ontology_name",
                exact       = if (exact) "true" else "false",
                rows        = 3L
            )
        if (!is.null(ontology) && !is.na(ontology))
            req <- httr2::req_url_query(req, ontology = tolower(ontology))
        req
    }
    do_search <- function(exact) {
        tryCatch(
            build_req(exact) |>
                httr2::req_throttle(rate = 5) |>
                httr2::req_retry(max_tries = 3L,
                                 is_transient = \(r) httr2::resp_status(r) == 429L) |>
                httr2::req_error(is_error = function(r) FALSE) |>
                httr2::req_perform() |>
                httr2::resp_body_json(),
            error = function(e) NULL
        )
    }
    resp <- do_search(exact = TRUE)
    docs <- resp[["response"]][["docs"]]
    if (is.null(docs) || length(docs) == 0L) {
        resp <- do_search(exact = FALSE)
        docs <- resp[["response"]][["docs"]]
    }
    if (is.null(docs) || length(docs) == 0L) return(NULL)
    doc <- docs[[1L]]
    list(term_label = doc[["label"]]         %||% NA_character_,
         term_iri   = doc[["iri"]]           %||% NA_character_,
         obo_id     = doc[["obo_id"]]        %||% NA_character_,
         ontology   = toupper(doc[["ontology_name"]] %||% NA_character_))
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
#' Uses a two-stage approach to avoid LLM hallucination under tool-call overload:
#' \enumerate{
#'   \item \strong{Concept extraction} — a plain LLM call (no tools) identifies
#'     all concepts in \code{query} and returns them as a character vector.
#'   \item \strong{Per-concept lookup} — each concept gets its own fresh
#'     single-turn chat so conversation history never accumulates across
#'     concepts.  The LLM calls an OLS4 tool and returns only a term label;
#'     R code resolves the label to a canonical IRI via OLS4 REST.
#' }
#' Results are validated against the EBI OLS4 REST API via
#' \code{\link{ols4_enrich}}, which adds \code{validated} and \code{definition}
#' columns.
#'
#' @param query character(1) free-text input containing one or more biological
#' or medical concepts.
#' @param provider character(1) LLM provider; see \code{\link{llm_env_var}}.
#' Defaults to \code{"anthropic"}.
#' @param model character(1) model identifier for the chosen provider.
#' Defaults to \code{"claude-sonnet-4-5"}.
#' @param temperature numeric(1) sampling temperature; defaults to \code{0}
#' for deterministic output.
#' @param extract_prompt character(1) prompt for Stage 1 (concept extraction).
#' Defaults to \code{inst/prompts/extract_concepts.txt}.
#' @param lookup_prompt character(1) prompt for Stage 2 (per-concept OLS4 lookup).
#' Defaults to \code{inst/prompts/lookup_concept.txt}.
#' @param max_concepts integer(1) maximum number of concepts to look up in
#' Stage 2.  The first \code{max_concepts} items from Stage 1 are used;
#' the rest are silently dropped.  \code{Inf} (default) processes all concepts.
#' @param deduplicate logical(1) if \code{TRUE} (default), rows with duplicate
#' \code{term_iri} values are collapsed into one row; the \code{input_text}
#' field of the surviving row lists all source concepts separated by \code{"; "}.
#' @param definition logical(1) if \code{FALSE} (default), the \code{definition}
#' column is set to \code{NA} and no extra OLS4 REST calls are made.  Set to
#' \code{TRUE} to fetch authoritative definitions via \code{\link{ols4_enrich}},
#' at the cost of one additional REST call per term.
#' @param label_match logical(1) if \code{TRUE}, adds \code{llm_label} and
#' \code{label_match} columns; implies \code{definition = TRUE} since it
#' requires \code{\link{ols4_enrich}}.  Defaults to \code{FALSE}.
#' @param ontology_filter character(1) or \code{NULL}.  When supplied, overrides
#' the ontology returned by the LLM and forces the OLS4 REST label search
#' to search within that ontology only (e.g. \code{"edam"}).  \code{NULL}
#' (default) uses whatever ontology the LLM selects.
#' @param tools list of ellmer \code{ToolDef} objects as returned by
#' \code{\link{ols4_mcp_tools}}.  Loaded once per \code{map_concepts} call;
#' each per-concept lookup creates a fresh chat that registers these tools,
#' preventing context accumulation across concepts.  Supply a pre-loaded tools
#' object to avoid restarting the MCP bridge on repeated calls.
#' @param extractor an ellmer \code{Chat} object \emph{without} tools, used for
#' Stage 1 concept extraction.  Defaults to a plain \code{\link{llm_chat}}
#' with the same provider, model, and temperature.
#' @return a data.frame with columns \code{input_text}, \code{term_label},
#' \code{term_iri}, \code{obo_id}, \code{ontology}, \code{rationale},
#' \code{validated}, and \code{definition}, one row per concept-term pair
#' (plus \code{llm_label} and \code{label_match} when \code{label_match=TRUE}).
#' \strong{Outputs require human curation.}  The LLM may return plausible-looking
#' but incorrect term mappings, particularly for concepts with ambiguous ontology
#' coverage.  Review \code{term_label} against \code{input_text} for each row
#' before treating results as authoritative.
#' @examples
#' if (interactive()) {
#'     map_concepts("atrial fibrillation and whole genome sequencing",
#'                  max_concepts = 10)
#'
#'     # pre-load tools to avoid restarting the MCP bridge on repeated calls
#'     tls <- ols4_mcp_tools()
#'     map_concepts("atrial fibrillation", tools = tls)
#'     map_concepts("whole genome sequencing", tools = tls)
#' }
#' @export
map_concepts <- function(query,
                         provider       = "anthropic",
                         model          = "claude-sonnet-4-5",
                         temperature    = 0,
                         extract_prompt = read_prompt("extract_concepts.txt"),
                         lookup_prompt  = read_prompt("lookup_concept.txt"),
                         max_concepts   = Inf,
                         deduplicate    = TRUE,
                         definition     = FALSE,
                         label_match    = FALSE,
                         ontology_filter = NULL,
                         tools          = ols4_mcp_tools(),
                         extractor      = llm_chat(provider = provider,
                                                    model    = model,
                                                    api_args = list(
                                                        temperature = temperature))) {
    # Stage 1: extract concept strings with no tool calls
    concepts <- extractor$chat_structured(
        paste0(extract_prompt, "\n\nInput text: ", query),
        type = ellmer::type_array(
            items = ellmer::type_string(
                "A biological, medical, or technical concept from the text"))
    )

    if (length(concepts) == 0L) {
        message("No concepts extracted from input text.")
        return(.empty_mapping_table())
    }
    if (is.finite(max_concepts) && length(concepts) > max_concepts) {
        message(sprintf("Extracted %d concept(s); limiting to first %d.",
                        length(concepts), max_concepts))
        concepts <- concepts[seq_len(max_concepts)]
    } else {
        message(sprintf("Extracted %d concept(s); querying OLS4 for each...",
                        length(concepts)))
    }

    # Stage 2: fresh single-turn chat per concept eliminates context accumulation.
    # LLM returns LABEL/ONTOLOGY/RATIONALE text — no IRI.
    # R code resolves label → IRI via OLS4 REST.
    make_lookup_chat <- function() {
        ch <- llm_chat(provider = provider, model = model,
                       api_args = list(temperature = temperature))
        ch$register_tools(tools)
        ch
    }

    rows <- lapply(seq_along(concepts), function(i) {
        concept <- concepts[[i]]
        message(sprintf("  [%d/%d] %s", i, length(concepts), concept))

        resp_text <- tryCatch(
            make_lookup_chat()$chat(
                paste0(lookup_prompt, "\n\nConcept: ", concept)),
            error = function(e) {
                message(sprintf("    chat failed: %s", conditionMessage(e)))
                NULL
            }
        )
        if (is.null(resp_text)) return(NULL)

        parsed <- .parse_label_response(resp_text)
        if (is.null(parsed)) {
            message(sprintf("    could not parse label response for '%s'", concept))
            return(NULL)
        }

        onto <- if (!is.null(ontology_filter)) ontology_filter else parsed$ontology
        iri_info <- .ols4_search_label(parsed$label, ontology = onto)
        if (is.null(iri_info)) {
            message(sprintf("    no OLS4 match for label '%s'", parsed$label))
            return(NULL)
        }

        data.frame(input_text = concept,
                   term_label = iri_info$term_label,
                   term_iri   = iri_info$term_iri,
                   obo_id     = iri_info$obo_id,
                   ontology   = iri_info$ontology,
                   rationale  = parsed$rationale,
                   stringsAsFactors = FALSE)
    })
    rows <- Filter(Negate(is.null), rows)

    if (length(rows) == 0L) {
        warning("All per-concept lookups failed.")
        return(.empty_mapping_table())
    }

    result <- do.call(rbind, rows)
    rownames(result) <- NULL

    if (definition || label_match) {
        result <- ols4_enrich(result, label_match = label_match)
    } else {
        result$validated  <- TRUE
        result$definition <- NA_character_
    }

    if (deduplicate && nrow(result) > 0L) {
        first   <- !duplicated(result$term_iri)
        merged  <- vapply(result$term_iri, function(iri) {
            paste(result$input_text[result$term_iri == iri], collapse = "; ")
        }, character(1L))
        result$input_text <- merged
        result <- result[first, , drop = FALSE]
        rownames(result) <- NULL
        n_dropped <- sum(!first)
        if (n_dropped > 0L)
            message(sprintf("Removed %d duplicate term(s) (same IRI).", n_dropped))
    }
    result
}

#' Map concepts to EDAM ontology terms via OLS4
#'
#' A focused wrapper around \code{\link{map_concepts}} that restricts all
#' ontology lookups to the EDAM ontology.  The LLM is instructed to search
#' within EDAM only and to identify which EDAM sub-tree applies (topic,
#' operation, data, or format); the OLS4 REST label search is also constrained
#' to EDAM regardless of the LLM's response.
#'
#' \strong{Scope and curation.}  EDAM covers bioinformatics operations, data
#' types, file formats, and computational biology topics.  Concepts outside
#' this scope — including spatial statistics, clinical phenotypes, chemical
#' entities, and general study designs — have little or no EDAM coverage.
#' When the input text contains such concepts the LLM may return a spurious
#' EDAM term rather than admitting no match exists.  \emph{All outputs should
#' be reviewed by a domain expert before use}: check that each
#' \code{term_label} is semantically appropriate for its \code{input_text},
#' and discard rows where the mapping is implausible.  The
#' \code{\link{map_concepts}} function (unrestricted ontology) may give better
#' coverage for mixed or clinically-oriented texts.
#'
#' @inheritParams map_concepts
#' @param \dots additional arguments passed to \code{\link{map_concepts}},
#' e.g. \code{max_concepts}, \code{deduplicate}, \code{definition}.
#' @return a data.frame as returned by \code{\link{map_concepts}}, with all
#' rows from the EDAM ontology.
#' @examples
#' if (interactive()) {
#'     map_concepts_edam("RNA-Seq workflow with variant calling and primer trimming",
#'                       max_concepts = 8)
#' }
#' @export
map_concepts_edam <- function(query, ...) {
    map_concepts(query,
                 lookup_prompt   = read_prompt("lookup_edam_concept.txt"),
                 ontology_filter = "edam",
                 ...)
}

# Return a zero-row data.frame with the expected post-enrich column set
.empty_mapping_table <- function() {
    data.frame(input_text = character(), term_label = character(),
               term_iri   = character(), obo_id     = character(),
               ontology   = character(), rationale  = character(),
               validated  = logical(),  definition = character(),
               stringsAsFactors = FALSE)
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
