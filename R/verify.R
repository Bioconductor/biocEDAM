#' given a data.frame with uri and tm produced by edamize (or mkdf),
#' check against the frozen EDAM term tables in biocEDAM, filtering records to
#' those whose uri matches a known id.
#' @param datf data.frame with at least a \code{uri} column containing EDAM URIs
#' (e.g. \code{"http://edamontology.org/topic_3308"})
#' @return a data.frame with the same structure as \code{datf}, restricted to
#' rows whose \code{uri} matches a term in the bundled EDAM vocabulary tables
#' @examples
#' df <- data.frame(
#'     uri = c("http://edamontology.org/topic_3308",
#'             "http://edamontology.org/topic_9999"),   # 9999 is not a real term
#'     tm  = c("Transcriptomics", "Made-up term"),
#'     stringsAsFactors = FALSE)
#' verify(df)  # returns only the row whose uri is in the known vocabulary
#' @export
verify = function (datf) 
{
    stopifnot("uri" %in% names(datf))
    data("edam_topics", package = "biocEDAM")
    data("edam_operations", package = "biocEDAM")
    data("edam_data", package = "biocEDAM")
    data("edam_formats", package = "biocEDAM")
    fulledam = do.call(rbind, list(edam_topics[[1]], edam_operations[[1]], 
        edam_data[[1]], edam_formats[[1]]))
    ids = datf$uri
    labs = datf$lbl
    actual = dplyr::filter(fulledam, id %in% ids)
    vvv = list(actual = actual, tagger = datf)
    vvv[[2]] |> dplyr::filter(uri %in% vvv[[1]]$id) |> dplyr::distinct()
}

