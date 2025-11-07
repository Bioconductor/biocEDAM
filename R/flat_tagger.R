#' simple tagger based on text excerpt and available context from data-frames with edam vocabularies
#' @import ellmer
#' @import btw
#' @param txt a text string for analysis
#' @param model a string naming an openai model
#' @param \dots parameters passed to chat_openai
#' @note This function as of Nov 7 2025 will routinely hallucinate associations and terms.
#' @examples
#' if (interactive()) {
#' txt = "The Voyager package is an R/Bioconductor software designed for exploratory spatial 
#' data analysis (ESDA) of spatial single-cell omics datasets. It operates on the 
#' SpatialFeatureExperiment (SFE) S4 class, allowing users to perform a wide range of spatial 
#' statistical analyses directly within a biological context. Univariate global spatial statistics 
#' supported include Moran's I for measuring spatial autocorrelation, permutation testing 
#' for assessing significance, and correlograms for examining spatial correlation structure. 
#' Bivariate spatial statistics implemented in Voyager comprise Lees L statistic 
#' and cross variograms for evaluating spatial associations between two 
#' variables. In addition, Voyager provides tools for multivariate analysis using methods 
#' such as MULTISPATI PCA, which integrates spatial structure into principal component 
#' analysis, and Anselins recent multivariate local Gearys C" 
#' flat_tagger(txt, nterms=12, model="gpt-4o")
#' }
#' @export
flat_tagger = function(txt, nterms = 20, model="gpt-5", ...) {
  message("This function does not avoid hallucinatory rewording of EDAM tags or construction of false tags")
  ch = chat_openai(model=model, ...)
  data("edam_topics", package="biocEDAM")
  data("edam_operations", package="biocEDAM")
  data("edam_data", package="biocEDAM")
  data("edam_formats", package="biocEDAM")
  dfstr = type_array(
   type_object(
    id = type_string(),
    lbl = type_string()
    )
   )
  ch$chat_structured(btw(edam_topics[[1]], edam_operations[[1]], edam_data[[1]], edam_formats[[1]]), sprintf("Provide around %d edam terms relevant to user query.  Return the results in an R data frame with one column giving the edam id, the other giving the label.  You are using the ellmer structured chat to facilitate return of a data frame.  The query is: Provide up to %d edam terms relevant to %s.  Try to provide balanced selections among concepts of format, data, operation, topic. Only use the literal text fields in the labels (lbl field) of the edam vocabulary maps.", 
      nterms, nterms, txt), type=dfstr) 
}
  

.verify = function(datf) {
  data("edam_topics", package="biocEDAM")
  data("edam_operations", package="biocEDAM")
  data("edam_data", package="biocEDAM")
  data("edam_formats", package="biocEDAM")
  fulledam = do.call(rbind, list(edam_topics[[1]], edam_operations[[1]], edam_data[[1]], edam_formats[[1]]))
  ids = datf$id
  labs = datf$lbl
  actual = fulledam |> dplyr::filter(id %in% ids)
  list(actual=actual, tagger=datf)
}
 
