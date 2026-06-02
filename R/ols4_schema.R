#' Ellmer type schema for a single ontology term mapping
#'
#' Describes one matched ontology term returned by an OLS4 MCP tool call.
#' Use with \code{chat$chat_structured()} to obtain validated, typed output.
#'
#' @format An ellmer \code{TypeObject} with fields:
#' \describe{
#'   \item{query}{The original natural language concept from the user query}
#'   \item{term_label}{The matched ontology term label}
#'   \item{term_iri}{The IRI/URI of the matched term}
#'   \item{obo_id}{The OBO-format ID, e.g. \code{GO:0007507}}
#'   \item{ontology}{Ontology short name, e.g. \code{GO}, \code{HP}, \code{MONDO}}
#'   \item{rationale}{Why this term was selected for this concept}
#' }
#' @seealso \code{\link{TermMappingTable}}, \code{\link{ols4_mcp_tools}}
#' @export
TermMapping <- ellmer::type_object(
    "TermMapping",
    query      = ellmer::type_string(
                     "The original natural language concept from the user query"),
    term_label = ellmer::type_string("The matched ontology term label"),
    term_iri   = ellmer::type_string("The IRI/URI of the matched term"),
    obo_id     = ellmer::type_string(
                     "The OBO-format ID, e.g. GO:0007507"),
    ontology   = ellmer::type_string(
                     "Ontology short name, e.g. GO, HP, MONDO"),
    rationale  = ellmer::type_string(
                     "Why this term was selected for this concept")
)

#' Ellmer type schema for a table of ontology term mappings
#'
#' An array of \code{\link{TermMapping}} objects, suitable for passing as the
#' \code{type} argument to \code{chat$chat_structured()} when multiple concepts
#' are to be mapped in a single call.
#'
#' @format An ellmer \code{TypeArray} whose items conform to
#' \code{\link{TermMapping}}.
#' @seealso \code{\link{TermMapping}}, \code{\link{ols4_mcp_tools}}
#' @export
TermMappingTable <- ellmer::type_array(items = TermMapping)
