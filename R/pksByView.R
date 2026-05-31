#' helper for package listing
#' @param views character() biocViews node values
#' @param type character(1) input to BiocPkgTools::biocPkgList
#' @param vlist list() if NULL, use biocPkgList to obtain current biocPkgList, otherwise
#' a named list with outputs of previous calls to biocPkgList
#' @return a data.frame with columns \code{pkg} and \code{view} for packages
#' matching the requested views
#' @examples
#' data("vlist", package="biocEDAM")
#' pksByViews(views = c("ChIPchip", "ShinyApps"), type="BioCsoft", vlist=vlist)
#' @export
pksByViews <- function(views, type="BioCsoft", vlist=NULL) {
 if (!is.null(vlist)) bb <- vlist[[type]]
 else bb <- BiocPkgTools::biocPkgList(repo=type)
 bv  <- bb$biocViews
 pk  <- bb$Package
 vl  <- vapply(bv, length, integer(1L))
 rpk <- rep(pk, vl)
 dd  <- data.frame(pkg=rpk, view=unlist(bv))
 dd[which(dd$view %in% views), ]
}
 
