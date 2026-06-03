#' @importFrom stats setNames
#' @importFrom utils data packageDescription readLines
NULL

#' Read a prompt template from the biocEDAM prompt library
#'
#' Loads a plain-text prompt file from \code{inst/prompts/} by name.
#' Use this to inspect the default prompt for any function, or to load it
#' as a starting point before modifying and passing to the \code{prompt=}
#' parameter of \code{\link{edamize}}, \code{\link{map_concepts}}, or
#' \code{\link{flat_tagger}}.
#'
#' @param name character(1) filename within \code{inst/prompts/}, e.g.
#' \code{"edamize.txt"}, \code{"map_concepts.txt"}, \code{"flat_tagger.txt"}.
#' @return character(1) the prompt text with trailing whitespace stripped.
#' @examples
#' cat(read_prompt("map_concepts.txt"))
#' @export
read_prompt <- function(name) {
    path <- system.file("prompts", name, package = "biocEDAM")
    if (!nchar(path))
        stop(sprintf("Prompt file '%s' not found in inst/prompts/", name))
    trimws(paste(readLines(path, warn = FALSE), collapse = "\n"),
           which = "right")
}

utils::globalVariables(c(
    # data objects loaded via data() in flat_tagger, verify, bvbrowse
    "edam_topics", "edam_operations", "edam_data", "edam_formats",
    "biocViewsVocab", "vlist", "allmap",
    # dplyr/filter variables
    "id", "uri", "Package"
))
