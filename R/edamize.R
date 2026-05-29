#' utility to "clean" odd characters in text input that seem to increase risk of json-transformation failures
#' @param x character(1) text from which non-alphabetic characters like brackets and parentheses
#' are to be removed
#' @note This is speculative; success rates appear to increase with no evident degradation of
#' content interpretation.
#' @export
cleantxt = function(x) gsub('-|\\(|`|#|:|\\*|’|"|\\[|\\]|\\$|\\{|\\}|=|\\(|\\||")', "", x)

#' simple utility to process output of edamize into data.frame
#' @import rjsoncons
#' @rawNamespace import(jsonlite, except=validate)
#' @param x a list as produced by edamize
#' @note dplyr::distinct is run on the result
#' @export
mkdf = function (x) 
{
    lkj = jsonlite::toJSON(x)
    uri = fromJSON(rjsoncons::j_query(lkj, "$..uri"))
    tm = fromJSON(rjsoncons::j_query(lkj, "$..term"))
    data.frame(uri, tm) |> dplyr::distinct()
}


# mods to Anh Vu's code in github.com/anngvu/bioc-curation
# aim is to run the code in R

#' use Anh Vu's prompting to develop structured metadata about
#' Bioconductor packages, targeting EDAM ontology and bio.tools schema
#' @import dplyr
#' @param content_for_edam character(1) a URL for doc originating from the developer
#' @param temp numeric(1) temperature setting for the LLM chat, defaults to 0.0
#' @param model character(1) model identifier for the selected provider;
#' defaults to "claude-sonnet-4-5" (Anthropic)
#' @param prescrub logical(1) if TRUE, apply the cleantxt function to the input before trying to assign EDAM tags;
#' defaults to TRUE
#' @param provider character(1) LLM provider for the Python path; one of "openai", "anthropic", or "gemini".
#' The value of the corresponding environment variable (see \code{\link{llm_env_var}}) is used as the API key
#' and the function stops with an informative error if the variable is not set.
#' Defaults to "anthropic".
#' @note This function is not deterministic.  For the provided example, the input to the function
#' is a fixed text, but the output at the end can be NULL, a data frame with 12 rows, or a data frame with 14 rows.
#' More work is needed to achieve greater predictability.
#' @note The result may possess redundant elements; mkdf will apply dplyr::distinct
#' @return a list with components 'topic' and 'function', which can be converted to a data.frame using `mkdf`
#' @examples
#' if (interactive()) {
#'   # ANTHROPIC_API_KEY must be set for the default provider
#'   content = readRDS(system.file("rds/tximetaFocused.rds", package="biocEDAM"))
#'   str(content)
#'   lk = edamize(content$focus)
#'   if (is.null(lk)) lk = edamize(content$focus)  # sometimes a second try is needed
#'   print(mkdf(lk))
#'   content2 = readRDS(system.file("rds/IRangesOVdata.rds", package="biocEDAM"))
#'   lk2 = edamize(content2$focus)
#'   mkdf(lk2)
#' }
#' @export
edamize = function(
     content_for_edam,
     temp = 0.0, model = "claude-sonnet-4-5", prescrub=TRUE, provider="anthropic") {
   if (!is.character(content_for_edam) || length(content_for_edam) != 1)
     stop("content_for_edam must be a single character string; did you mean to pass e.g. tst$focused?")
   requireNamespace("reticulate")
   api_key = llm_api_key(provider)
   # copy to tempdir to avoid python import problems with the installed path
   tdir = tempdir()
   file.copy(system.file("curbioc", package="biocEDAM"), tdir, recursive=TRUE)
   curbioc = reticulate::import_from_path("curbioc.curbioc", path=tdir, convert=FALSE)
   json = reticulate::import("json", convert=FALSE)
   curbioc$init_client(api_key=api_key, provider=provider, model=model)

   edam_schema = curbioc$get_text_from_url("https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/edammap.json")
   edam_validation = json$loads(edam_schema)

   if (prescrub) content_for_edam = cleantxt(content_for_edam)
   edam_json = try(curbioc$schema_completion(content_for_edam, edam_schema, temp=temp))
   if (inherits(edam_json, "try-error")) {
     warning("schema_completion failed")
     return(NULL)
   }
   edam_final = try(curbioc$validate_json_with_retries(edam_json, edam_validation))
   if (inherits(edam_final, "try-error")) {
     warning("JSON validation failed after retries")
     return(NULL)
   }
   edam_processed = curbioc$transform_terms(edam_final)
   reticulate::py_to_r(edam_processed)
}
   
