#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
    stop("Usage: Rscript fetch_weather_open_meteo.R <output_csv>")
}

output_csv <- args[1]

if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Install with install.packages('jsonlite').")
}

latitude <- 35.22
longitude <- -101.83

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
cat(paste("Fetched Open-Meteo weather for", latitude, longitude, "and wrote", output_csv))
