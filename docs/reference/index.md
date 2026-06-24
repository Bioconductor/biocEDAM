<div id="main" class="col-md-9" role="main">

# Package index

<div class="section level2">

## All functions

</div>

<div class="section level2">

-   `TermMapping` : Ellmer type schema for a single ontology term
    mapping
-   `TermMappingTable` : Ellmer type schema for a table of ontology term
    mappings
-   `allmap` : map from biocViews to EDAM
-   `bioc_line()` : use BiocPkgTools to acquire metadata on a specified
    Bioconductor package
-   `biotools_bioc` : result of scanning biotools metadata on 3 Nov 2024
    to find bioconductor packages and EDAM topics
-   `bvbrowse()` : interactive exploration of biocViews in relation to
    packages
-   `cleantxt()` : utility to "clean" odd characters in text input that
    seem to increase risk of LLM failures
-   `curate_bioc()` : use Anh Vu's prompting to develop structured
    metadata about Bioconductor packages, targeting EDAM ontology and
    bio.tools schema
-   `edam_data` : snapshot of edam data circa early 2024
-   `edam_formats` : snapshot of edam formats circa early 2024
-   `edam_graph()` : build a graph of EDAM terms deemed relevant to a
    text
-   `edam_operations` : snapshot of edam operations circa early 2024
-   `edam_topics` : snapshot of edam topics circa early 2024
-   `edamize()` : Assign EDAM ontology terms to text using a live
    SemanticSQL database and an LLM
-   `extract_uri()` : Helper recursive function to extract 'uri' nodes
    from JSON document based on edamize
-   `flat_tagger()` : simple tagger based on text excerpt and available
    context from data-frames with edam vocabularies
-   `get_edam_embeddings()` : Retrieve pre-computed EDAM term embeddings
    from AnnotationHub
-   `llm_api_key()` : Retrieve the API key for an LLM provider from the
    environment
-   `llm_chat()` : Create an ellmer chat object for a given LLM provider
-   `llm_env_var()` : Map an LLM provider name to its environment
    variable
-   `make_edam_embeddings()` : Generate and save EDAM term embeddings
-   `map_concepts()` : Map biological or medical concepts to ontology
    terms via OLS4
-   `mapping_to_json()` : Export a map\_concepts result as a JSON
    document
-   `mkdf()` : simple utility to process output of edamize into a
    data.frame
-   `ols4_chat()` : Create an ellmer chat pre-wired with EBI OLS4 MCP
    tools
-   `ols4_enrich()` : Validate and enrich a TermMappingTable via the
    OLS4 REST API
-   `ols4_mcp_tools()` : List tools available from the EBI OLS4 MCP
    service
-   `ols4_tool_table()` : Summarise OLS4 MCP tools as a data frame
-   `pksByViews()` : helper for package listing
-   `read_prompt()` : Read a prompt template from the biocEDAM prompt
    library
-   `retrieve_edam_candidates()` : Retrieve the top-k semantically
    closest EDAM terms per type
-   `saved_views_2023.18.11` : dated set of biocViews
-   `tag_bioc()` : full workflow to tag a bioconductor package and
    selected representative content with EDAM terms
-   `toline()` : process the output of edamize followed by mkdf to
    create a data frame with components topic, operation, data, format,
    reflecting main elements of EDAM
-   `verify()` : given a data.frame with uri and tm produced by edamize
    (or mkdf), check against the frozen EDAM term tables in biocEDAM,
    filtering records to those whose uri matches a known id.
-   `vig2data()` : Use the extract\_data facility defined in ellmer's
    doc to obtain summary information about textual content. Originally
    tailored to vignettes in bioconductor; it is newly generalized to
    handle any pdf, html or text in URL.
-   `vlist` : snapshot of all biocViews

</div>

</div>
