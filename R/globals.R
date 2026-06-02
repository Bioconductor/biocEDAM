#' @importFrom stats setNames
#' @importFrom utils data packageDescription
NULL

utils::globalVariables(c(
    # data objects loaded via data() in flat_tagger, verify, bvbrowse
    "edam_topics", "edam_operations", "edam_data", "edam_formats",
    "biocViewsVocab", "vlist", "allmap",
    # dplyr/filter variables
    "id", "uri", "Package"
))
