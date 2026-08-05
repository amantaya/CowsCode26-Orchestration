#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript summarize_livestock_api.R <input_json> <output_csv>")
}

input_json <- args[1]
output_csv <- args[2]

if (!file.exists(input_json)) {
  stop(paste("Input JSON file does not exist:", input_json))
}

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Install with install.packages('jsonlite').")
}

payload <- jsonlite::fromJSON(input_json)

summary_df <- data.frame(
  fetched_at_utc = payload$fetched_at_utc,
  source = payload$source,
  slide_count = length(payload$payload$slideshow$slides),
  stringsAsFactors = FALSE
)

write.csv(summary_df, output_csv, row.names = FALSE)
cat(paste("Wrote", output_csv))
