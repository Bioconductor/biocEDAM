<div id="main" class="col-md-9" role="main">

# List tools available from the EBI OLS4 MCP service

<div class="ref-description section level2">

Connects to the EBI OLS4 Ontology Lookup Service MCP endpoint using
`mcp-remote` as a local stdio-to-Streamable-HTTP bridge, and returns the
available tools as ellmer tool objects ready for use in an LLM chat.

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
ols4_mcp_tools(url = "https://www.ebi.ac.uk/ols4/api/mcp")
```

</div>

</div>

<div class="section level2">

## Arguments

-   url:

    character(1) URL of the EBI OLS4 MCP endpoint. Defaults to
    `"https://www.ebi.ac.uk/ols4/api/mcp"`.

</div>

<div class="section level2">

## Value

a named list of ellmer `ToolDef` objects, one per tool exposed by the
service. Pass directly to an ellmer chat's tool registration, or
summarise with `ols4_tool_table`.

</div>

<div class="section level2">

## Note

Requires `npx` and `mcp-remote` on the system PATH. Install the bridge
once with:

<div class="sourceCode">

    npm install -g mcp-remote

</div>

The bridge translates stdio MCP (which mcptools speaks) into the
Streamable HTTP transport used by the EBI OLS4 endpoint.

</div>

<div class="section level2">

## Examples

<div class="sourceCode">

``` r
if (interactive()) {
    tools <- ols4_mcp_tools()
    ols4_tool_table(tools)
}
```

</div>

</div>

</div>
