

# mods to Anh Vu's code in github.com/anngvu/bioc-curation
# aim is to run the code in R

#' use Anh Vu's prompting to develop structured metadata about
#' Bioconductor packages, targeting EDAM ontology and bio.tools schema
#' @param packageName character(1) a Bioconductor software package name, its release landing page will be scraped
#' @param devurl character(1) a URL for doc originating from the developer
#' @param model character(1) model identifier for the selected provider; defaults to "gpt-4o" (OpenAI)
#' @param provider character(1) LLM provider for the Python path; currently only "openai" is supported.
#' The value of the corresponding environment variable (see \code{\link{llm_env_var}}) is used as the API key
#' and the function stops with an informative error if the variable is not set.
#' @return two python dicts, base_final and edam_processed
#' @note Schema completion is done with temperature set to 0.0; see edamize function for more flexibility.
#' @examples
#' if (interactive()) {
#'   # OPENAI_API_KEY must be set for the default provider
#'   lk = curate_bioc()
#'   str(lk)
#' }
#' @export
curate_bioc = function(packageName="chromVAR",
     devurl = "https://raw.githubusercontent.com/GreenleafLab/chromVAR/refs/heads/master/README.md",
     model="claude-sonnet-4-5", provider="anthropic") {
   requireNamespace("reticulate")
   api_key = llm_api_key(provider)
   requests = reticulate::import("requests", convert=FALSE)
   tdir = tempdir()
   file.copy(system.file("curbioc", package="biocEDAM"), tdir, recursive=TRUE)
   curbioc = reticulate::import_from_path("curbioc.curbioc", path=tdir, convert=FALSE)
   json = reticulate::import("json", convert=FALSE)
   curbioc$init_client(api_key=api_key, provider=provider, model=model)
   
   # Retrieve text from example sources for the package chromVAR
   # Sources to curate from can be Bioconductor homepage, READMEs, vignettes, paper (if acccessible), function docs, ...
   
   # Change urls to use selected material for different packages
   baseurl = sprintf("https://bioconductor.org/packages/release/bioc/html/%s.html", packageName)
   base_content = curbioc$get_text_from_url(baseurl)
   
   edam_content = curbioc$get_text_from_url(devurl, trim=TRUE)
   
   #
   ## Retrieve schemas
   #
   ## Base

   base_schema = curbioc$get_text_from_url("https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/base.json")
   base_validation = json$loads(base_schema)
   #

   # EDAM

   edam_schema = curbioc$get_text_from_url("https://raw.githubusercontent.com/anngvu/bioc-curation/refs/heads/main/edammap.json")
   edam_validation = json$loads(edam_schema)
   #
   ## Original -- not used until last step
   biotools_original = curbioc$get_text_from_url("https://raw.githubusercontent.com/bio-tools/biotoolsSchema/refs/heads/main/jsonschema/biotoolsj.json")
   biotools_original_validation = json$loads(biotools_original) 

   #
   ## Base schema completion
   #
   
   base_json = curbioc$schema_completion(base_content, base_schema, temp=0.0)
   base_final = curbioc$validate_json_with_retries(base_json, base_validation)

   #
   ## EDAM schema completion
   #
   edam_json = curbioc$schema_completion(edam_content, edam_schema, temp=0.0)
   edam_final = curbioc$validate_json_with_retries(edam_json, edam_validation)
   
   edam_processed = curbioc$transform_terms(edam_final)
   edam_processed

 list(base_final = base_final, edam_processed = edam_processed )
}
   
   #
   ## One manual fix
   #
   ## final_fix = validate_json_with_retries(str(ai_curated), biotools_original_validation)
   #ai_curated[0]['credit'][0]['email'] = "aschep@gmail.com"
   #validate(ai_curated, biotools_original_validation)
   #
   #with open('ai_curated_1.json', 'w') as f:
   #    json.dump(ai_curated, f, indent=4)
   #
