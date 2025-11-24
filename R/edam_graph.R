
#' Helper recursive function to extract 'uri' nodes from JSON document based on edamize
#' @param node a JSON document
#' @note From perplexity.ai
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
#' @param \dots passed to ontoProc::onto_plot2
#' @note The text is expected to be generated as the 'focused' result
#' of vig2data; it will then be processed by 'edamize'
#' @examples
#' if (interactive()) {
#' requireNamespace("ontoProc2")
#' stopifnot(nchar(Sys.getenv("OPENAI_API_KEY"))>0)
#' eg = readRDS(system.file("rds", "edam_1.25_ontoindex.rds", package="biocEDAM"))
#' statescoper = readRDS(system.file("rds", "tgac-vumc_StatescopeR.rds", package="biocEDAM"))
#' edam_graph(statescoper$focused, eg, cex=.3) 
#' }
#' @export
edam_graph = function(txt, edam_graph, ...) {
 ed = biocEDAM::edamize(txt) # uses openAI API
 tf = tempfile()
 on.exit(unlink(tf))
 jsonlite::write_json(ed, path=tf)  # probably unnecessary, do in memory
 jstr = jsonlite::read_json(tf)
 allu = extract_uri(jstr)
 allu = sapply(allu, function(x) gsub("http://edamontology.org/", "", x))
 allu = gsub("_", ":", allu)
 ontoProc::onto_plot2(edam_graph, allu, ...)
}
