#' result of scanning biotools metadata on 3 Nov 2024 to find bioconductor packages and EDAM topics
#' @docType data
#' @note Used R code to scrape `https://github.com/research-software-ecosystem/content` to obtain this table.
#' See code in 'inst/scrapes' folder in biocEDAM package.
"biotools_bioc"

#' map from biocViews to EDAM
#' @docType data
#' @note uses pypi text2term
"allmap"

#' dated set of biocViews
#' @docType data
"saved_views_2023.18.11"

#' snapshot of all biocViews
#' @docType data
#' @examples
#' data(vlist)
#' sapply(vlist,nrow)
#' dim(vlist[[1]])
"vlist"

#' snapshot of edam topics circa early 2024
#' @docType data
#' @format list with data.frame
"edam_topics"

#' snapshot of edam formats circa early 2024
#' @docType data
#' @format list with data.frame
"edam_formats"

#' snapshot of edam operations circa early 2024
#' @docType data
#' @format list with data.frame
"edam_operations"

#' snapshot of edam data circa early 2024
#' @docType data
#' @format list with data.frame
"edam_data"
