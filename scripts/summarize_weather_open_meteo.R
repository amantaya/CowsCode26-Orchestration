#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
    stop("Usage: Rscript summarize_weather_open_meteo.R <input_csv> <output_csv>")
}

input_csv <- args[1]
output_csv <- args[2]

if (!file.exists(input_csv)) {
    stop(paste("Input CSV file does not exist:", input_csv))
}

weather_df <- read.csv(input_csv, stringsAsFactors = FALSE)

summary_df <- data.frame(
    fetched_at_utc = weather_df$fetched_at_utc,
    latitude = weather_df$latitude,
    longitude = weather_df$longitude,
    temperature_2m_c = weather_df$temperature_2m_c,
    relative_humidity_pct = weather_df$relative_humidity_pct,
    wind_speed_10m_kmh = weather_df$wind_speed_10m_kmh,
    precipitation_mm = weather_df$precipitation_mm,
    heat_load_score = round(
        weather_df$temperature_2m_c +
            (weather_df$relative_humidity_pct / 10) -
            (weather_df$wind_speed_10m_kmh / 20),
        2
    ),
    stringsAsFactors = FALSE
)

write.csv(summary_df, output_csv, row.names = FALSE)
cat(paste("Wrote", output_csv))
