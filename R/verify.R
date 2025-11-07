#' given a data.frame with uri and lbl produced by mkdf after edamize,
#' check against the edam tables in biocEDAM, filtering records to
#' those with id matching the uri.  the result should give TRUE
#' for all.equal: all.equal(datf, verify(datf))
#' @examples
#' content = readRDS(system.file("rds/tximetaFocused.rds", package="biocEDAM"))
#' str(content)
#' lk = edamize(content$focus)
#' da = mkdf(lk)
#' chk = verify(da)
#' all.equal(da, chk)
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

