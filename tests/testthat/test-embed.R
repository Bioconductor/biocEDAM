test_that("get_edam_embeddings loads the bundled artifact", {
    emb <- get_edam_embeddings()
    expect_type(emb, "list")
    expect_true(all(c("ids", "labels", "types", "texts",
                      "embeddings", "model") %in% names(emb)))
    expect_true(is.matrix(emb$embeddings))
    n <- length(emb$ids)
    expect_equal(length(emb$labels),   n)
    expect_equal(length(emb$types),    n)
    expect_equal(length(emb$texts),    n)
    expect_equal(nrow(emb$embeddings), n)
    expect_true(n > 100L)
    expect_setequal(unique(emb$types),
                    c("topic", "operation", "data", "format"))
})

test_that("get_edam_embeddings artifact uses text-embedding-3-small", {
    emb <- get_edam_embeddings()
    expect_equal(emb$model, "text-embedding-3-small")
    expect_equal(ncol(emb$embeddings), 1536L)
})

test_that("get_edam_embeddings honours EDAM_EMBEDDING_RDS env var", {
    emb     <- get_edam_embeddings()
    tmp     <- tempfile(fileext = ".rds")
    saveRDS(emb, tmp)
    old <- Sys.getenv("EDAM_EMBEDDING_RDS", unset = "")
    on.exit({
        if (nchar(old)) Sys.setenv(EDAM_EMBEDDING_RDS = old)
        else Sys.unsetenv("EDAM_EMBEDDING_RDS")
        unlink(tmp)
    })
    Sys.setenv(EDAM_EMBEDDING_RDS = tmp)
    emb2 <- get_edam_embeddings()
    expect_equal(emb2$model, emb$model)
})

test_that("get_edam_embeddings errors on missing EDAM_EMBEDDING_RDS path", {
    old <- Sys.getenv("EDAM_EMBEDDING_RDS", unset = "")
    on.exit({
        if (nchar(old)) Sys.setenv(EDAM_EMBEDDING_RDS = old)
        else Sys.unsetenv("EDAM_EMBEDDING_RDS")
    })
    Sys.setenv(EDAM_EMBEDDING_RDS = "/nonexistent/path/edam.rds")
    expect_error(get_edam_embeddings(), "does not exist")
})

test_that("retrieve_edam_candidates stops on model mismatch", {
    emb <- get_edam_embeddings()
    expect_error(
        retrieve_edam_candidates("some text", emb,
                                  embed_model = "text-embedding-3-large"),
        "does not match the artifact model"
    )
})
