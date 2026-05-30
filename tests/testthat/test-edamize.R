test_that("cleantxt removes special characters", {
    expect_equal(cleantxt("RNA-seq (paired)"), "RNAseq paired)")  # ) not in pattern
    expect_equal(cleantxt("foo#bar:baz"), "foobarbaz")
    expect_equal(cleantxt("normal text"), "normal text")
    expect_false(grepl("-", cleantxt("RNA-seq")))   # dash removed
    expect_false(grepl("\\(", cleantxt("(test")))  # open paren removed
})

test_that("mkdf passes through a data.frame unchanged", {
    df <- data.frame(uri = "http://edamontology.org/topic_3308",
                     tm  = "Transcriptomics",
                     stringsAsFactors = FALSE)
    expect_identical(mkdf(df), dplyr::distinct(df))
})

test_that("edamize stops on non-character input", {
    expect_error(edamize(list(a = 1)), "single character string")
})

test_that("edamize stops on length > 1 character input", {
    expect_error(edamize(c("one", "two")), "single character string")
})

test_that("toline parses EDAM URIs into typed columns", {
    df <- data.frame(
        uri = c("http://edamontology.org/topic_3308",
                "http://edamontology.org/operation_2238",
                "http://edamontology.org/data_3112",
                "http://edamontology.org/format_3475"),
        tm  = c("Transcriptomics", "Statistical calculation",
                "Gene expression matrix", "TSV"),
        stringsAsFactors = FALSE
    )
    out <- toline(df)
    expect_true(is.data.frame(out))
    expect_true("topic"     %in% names(out))
    expect_true("operation" %in% names(out))
    expect_true("data"      %in% names(out))
    expect_true("format"    %in% names(out))
    expect_match(out$topic,  "Transcriptomics")
    expect_match(out$format, "TSV")
})
