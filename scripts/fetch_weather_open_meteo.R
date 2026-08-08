#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
    stop("Usage: Rscript fetch_weather_open_meteo.R <output_csv>")
}

output_csv <- args[1]

build_timestamped_path <- function(path) {
    extension <- tools::file_ext(path)
    stem <- if (nzchar(extension)) {
        sub(paste0("\\.", extension, "$"), "", path)
    } else {
        path
    }

    timestamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")

    if (nzchar(extension)) {
        paste0(stem, "_", timestamp, ".", extension)
    } else {
        paste0(stem, "_", timestamp)
    }
}

output_csv <- build_timestamped_path(output_csv)

if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Install with install.packages('jsonlite').")
}

latitude <- 36.116
longitude <- -97.058

url <- paste0(
    "https://api.open-meteo.com/v1/forecast?latitude=",
    latitude,
    "&longitude=",
    longitude,
    "&current=temperature_2m,relative_humidity_2m,wind_speed_10m,precipitation&timezone=UTC"
)

payload <- jsonlite::fromJSON(url)

weather_df <- data.frame(
    fetched_at_utc = payload$current$time,
    latitude = payload$latitude,
    longitude = payload$longitude,
    temperature_2m_c = payload$current$temperature_2m,
    relative_humidity_pct = payload$current$relative_humidity_2m,
    wind_speed_10m_kmh = payload$current$wind_speed_10m,
    precipitation_mm = payload$current$precipitation,
    stringsAsFactors = FALSE
)

write.csv(weather_df, output_csv, row.names = FALSE)
cat(
    sprintf(
        "Fetched Open-Meteo weather for %s %s and wrote %s\nOUTPUT_CSV=%s\n",
        latitude,
        longitude,
        output_csv,
        output_csv
    )
)
