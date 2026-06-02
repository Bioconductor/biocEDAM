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
ols4_chat <- function(provider = "anthropic",
                      model    = "claude-sonnet-4-5",
                      url      = "https://www.ebi.ac.uk/ols4/api/mcp",
                      ...) {
    tools <- ols4_mcp_tools(url = url)
    chat  <- llm_chat(provider = provider, model = model, ...)
    chat$register_tools(tools)
    chat
}

#' Map biological or medical concepts to ontology terms via OLS4
#'
#' Sends \code{query} to an ellmer chat that has EBI OLS4 search tools
#' registered, asking the LLM to identify concepts and retrieve the best
#' matching ontology terms.  Returns a typed data frame conforming to
#' \code{\link{TermMappingTable}}.
#'
#' @param query character(1) free-text query containing one or more biological
#' or medical concepts.
#' @param chat an ellmer \code{Chat} object with OLS4 tools registered; created
#' by \code{\link{ols4_chat}} if not supplied.  Reuse across calls to avoid
#' restarting the bridge process.
#' @return a data.frame with columns \code{query}, \code{term_label},
#' \code{term_iri}, \code{obo_id}, \code{ontology}, and \code{rationale},
#' one row per concept-term pair.
#' @examples
#' if (interactive()) {
#'     ch <- ols4_chat()
#'     map_concepts("spatial autocorrelation in gene expression", chat = ch)
#'     map_concepts("chromatin accessibility", chat = ch)
#' }
#' @export
map_concepts <- function(query,
                         chat = ols4_chat()) {
    chat$chat_structured(
        paste0(
            "For each biological or medical concept in the following query, ",
            "use the OLS search tools to find the best matching ontology terms. ",
            "Prefer HP for phenotypes, MONDO for diseases, GO for processes, ",
            "ChEBI for chemicals. Return one row per concept-term pair.\n\n",
            "Query: ", query
        ),
        type = TermMappingTable
    )
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
