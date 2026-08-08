#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: write_data_duckdb.R <data_dir> <output_db> <mode>")
}

library(duckdb)
library(DBI)

input_dir <- normalizePath(args[1], winslash = '/', mustWork = TRUE)
output_db <- normalizePath(args[2], winslash = '/', mustWork = FALSE)
mode <- args[3]

if (!dir.exists(dirname(output_db))) {
  dir.create(dirname(output_db), recursive = TRUE, showWarnings = FALSE)
}

csv_files <- list.files(input_dir, pattern = "\\.(csv|CSV)$", full.names = TRUE, recursive = TRUE)
if (length(csv_files) == 0) {
  stop(sprintf("No CSV files found under %s", input_dir))
}

con <- dbConnect(duckdb::duckdb(), dbdir = output_db)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

if (mode == "all") {
  dbRemoveTable(con, "accelerometer_raw", fail_if_missing = FALSE)
  dbRemoveTable(con, "movement_intensity", fail_if_missing = FALSE)

  for (csv_file in csv_files) {
    data <- read.csv(csv_file, header = FALSE, sep = ",", skip = 8, stringsAsFactors = FALSE)
    names(data) <- c("Time", "Ax", "Ay", "Az")
    data$source_file <- basename(csv_file)
    data$ingested_at <- Sys.time()
    dbWriteTable(con, name = "accelerometer_raw", value = data, append = TRUE, overwrite = FALSE)
  }
  message(sprintf("Loaded %d CSV files into %s", length(csv_files), output_db))
} else if (mode == "summarize") {
  if (!dbExistsTable(con, "accelerometer_raw")) {
    stop("accelerometer_raw table does not exist yet; run the all mode first")
  }
  intensity_query <- "
    CREATE OR REPLACE TABLE movement_intensity AS
    SELECT
      source_file,
      AVG((Ax^2 + Ay^2 + Az^2)^0.5) AS mean_vector_magnitude,
      MAX((Ax^2 + Ay^2 + Az^2)^0.5) AS max_vector_magnitude,
      COUNT(*) AS n_observations
    FROM accelerometer_raw
    GROUP BY source_file
  "
  dbExecute(con, intensity_query)
  message("Calculated movement intensity summary")
} else {
  stop(sprintf("Unsupported mode: %s", mode))
}
