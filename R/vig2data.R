
#' use the extract_data facility defined in ellmer's doc to obtain summary information about an html
#' document, tailored to vignettes in bioconductor; newly generalized to handle any text in URL
#' @import rvest pdftools ellmer
#' @param url character(1) URL for an html bioconductor vignettes
#' @param maxnchar numeric(1) text is truncated to a substring with this length
#' @param n_pdf_pages numeric(1) maximum number of pages to extract text from for pdf vignettes
#' @return a list with components author, topics, focused, coherence, and persuasion
#' @note Based on code from https://cran.r-project.org/web/packages/ellmer/vignettes/structured-data.html
#' March 15 2025.  Requires that OPENAI_API_KEY is available in environment.
#' @examples
#' if (interactive()) {
#' # be sure OPENAI_API_KEY is available to Sys.getenv
#' tst = vig2data()
#' str(tst)
#' }
#' @export
vig2data = function(url ="https://bioconductor.org/packages/release/bioc/html/Voyager.html",
   maxnchar=30000, n_pdf_pages=10) {
 isHTML = isTRUE(length(grep("\\.html$", basename(url)))>0)
 isPDF = isTRUE(length(grep("\\.pdf$", basename(url)))>0)
 if (isHTML) {
   html <- rvest::read_html(url)
   text <- rvest::html_text2(rvest::html_element(html, "body"))
   }
 else if (isPDF) {
   dat <- pdftools::pdf_data(url)
   np = length(dat)
   lim = min(c(n_pdf_pages, np))
   tmp = lapply(dat[seq_len(lim)], function (x) x$text)
   strs = lapply(tmp, paste, collapse=" ")
   text <- paste(strs, collapse=" ")
   }
 else text = paste(readLines(url), collapse = " ")

 type_summary <- type_object(
  .description = "Summary of the article.",
  author = type_array(description = "Name of the article author(s)", type_string(),),
  topics = type_array(
    description='Array of topics in the biosciences, e.g. ["DNA", "RNA", "chromosomal positions", "genes"]. Should be as specific as possible, and can overlap.',
    type_string()
  ),
  focused = type_string(description = "Provide a concise summary of the article using distinctive vocabulary that would be helpful for embedding the summarized content.  Avoid subjective judgmental commentary.  Avoid generalities about hypotheses and generic activities of data analysis.  Limit the summary to 450 words."),
  coherence = type_integer("Coherence of the article's key points, 0-100 (inclusive)"),
  persuasion = type_number("Article's persuasion score, 0.0-1.0 (inclusive)")
 )

 chat <- chat_openai()
 chat$chat_structured(substr(text,1,maxnchar), type = type_summary)
}

