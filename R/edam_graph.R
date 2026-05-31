
#' Helper recursive function to extract 'uri' nodes from JSON document based on edamize
#' @param node a JSON document (list)
#' @return a list of URI strings extracted from \code{node}
#' @note From perplexity.ai
#' @examples
#' node <- list(uri = "http://edamontology.org/topic_3308",
#'              children = list(
#'                  list(uri = "http://edamontology.org/topic_3170")))
#' extract_uri(node)
#' @export
extract_uri <- function(node) {
  uris <- list()
  if (is.list(node)) {
    for (item in node) {
      uris <- c(uris, extract_uri(item))
    }
  }
  if (!is.null(names(node)) && "uri" %in% names(node)) {
    uris <- c(uris, node$uri)
  }
  return(uris)
}


#' build a graph of EDAM terms deemed relevant to a text
#' @importFrom jsonlite write_json read_json
#' @param txt string, typically describing a software artifact
#' @param edam_graph an ontologyIndex ontology-index instance representing EDAM
#' @param provider character(1) LLM provider; see \code{\link{llm_env_var}}. Defaults to "anthropic".
#' @param \dots passed to ontoProc::onto_plot2
#' @return called for its side effect (a graph plot); returns the result of
#' \code{ontoProc::onto_plot2} invisibly
#' @note The text is expected to be generated as the 'focused' result
#' of vig2data; it will then be processed by 'edamize'
#' @examples
#' if (interactive()) {
#' requireNamespace("ontoProc2")
#' eg = readRDS(system.file("rds", "edam_1.25_ontoindex.rds", package="biocEDAM"))
#' statescoper = readRDS(system.file("rds", "tgac-vumc_StatescopeR.rds", package="biocEDAM"))
#' edam_graph(statescoper$focused, eg, cex=.3)
#' }
#' @export
edam_graph <- function(txt, edam_graph, provider="anthropic", ...) {
 ed  <- biocEDAM::edamize(txt, provider=provider)
 tf  <- tempfile()
 on.exit(unlink(tf))
 jsonlite::write_json(ed, path=tf)
 jstr <- jsonlite::read_json(tf)
 allu <- extract_uri(jstr)
 allu <- vapply(allu, function(x) gsub("http://edamontology.org/", "", x),
                character(1L))
 allu <- gsub("_", ":", allu)
 ontoProc::onto_plot2(edam_graph, allu, ...)
}
