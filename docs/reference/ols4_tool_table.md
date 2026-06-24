<div id="main" class="col-md-9" role="main">

# Summarise OLS4 MCP tools as a data frame

<div class="ref-description section level2">

Summarise OLS4 MCP tools as a data frame

</div>

<div class="section level2">

## Usage

<div class="sourceCode">

``` r
ols4_tool_table(tools)
```

</div>

</div>

<div class="section level2">

## Arguments

-   tools:

    list of ellmer tool objects as returned by `ols4_mcp_tools`.

</div>

<div class="section level2">

## Value

a data.frame with columns `name` and `description`, one row per tool.

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
