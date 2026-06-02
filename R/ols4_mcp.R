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
