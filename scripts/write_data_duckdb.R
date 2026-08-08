#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: write_data_duckdb.R <data_dir> <output_db> <mode>")
}

library(duckdb)
library(DBI)

extract_start_time <- function(csv_file) {
  header_lines <- readLines(csv_file, n = 8, warn = FALSE)
  start_line <- header_lines[grepl("^;Start_time,", header_lines)]

  if (length(start_line) == 0) {
    stop(sprintf("Missing Start_time header in %s", csv_file))
  }

  parts <- trimws(strsplit(start_line[[1]], ",")[[1]])
  if (length(parts) < 3) {
    stop(sprintf("Invalid Start_time header in %s", csv_file))
  }

  as.POSIXct(
    paste(parts[2], parts[3]),
    format = "%Y-%m-%d %H:%M:%OS",
    tz = "UTC"
  )
}

input_dir <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
output_db <- normalizePath(args[2], winslash = "/", mustWork = FALSE)
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
    recording_start_time <- extract_start_time(csv_file)
    data$source_file <- basename(csv_file)
    data$recording_start_time <- recording_start_time
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
      recording_start_time + (Time * INTERVAL '1 second') AS sample_timestamp,
      strftime(recording_start_time + (Time * INTERVAL '1 second'), '%H:%M:%S') AS time_of_day,
      EXTRACT('hour' FROM recording_start_time + (Time * INTERVAL '1 second')) * 3600
        + EXTRACT('minute' FROM recording_start_time + (Time * INTERVAL '1 second')) * 60
        + EXTRACT('second' FROM recording_start_time + (Time * INTERVAL '1 second')) AS seconds_since_midnight,
      source_file,
      Time AS seconds_since_recording_start,
      (Ax^2 + Ay^2 + Az^2)^0.5 AS vector_magnitude
    FROM accelerometer_raw
    ORDER BY sample_timestamp, source_file
  "
  dbExecute(con, intensity_query)
  message("Calculated movement intensity time series")
} else {
  stop(sprintf("Unsupported mode: %s", mode))
}
