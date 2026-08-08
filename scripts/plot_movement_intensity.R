#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
    stop("Usage: plot_movement_intensity.R <input_db> <output_png>")
}

library(duckdb)
library(DBI)

input_db <- normalizePath(args[1], winslash = "/", mustWork = TRUE)
output_png <- normalizePath(args[2], winslash = "/", mustWork = FALSE)

if (!dir.exists(dirname(output_png))) {
    dir.create(dirname(output_png), recursive = TRUE, showWarnings = FALSE)
}

con <- dbConnect(duckdb::duckdb(), dbdir = input_db, read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

if (!dbExistsTable(con, "movement_intensity")) {
    stop("movement_intensity table does not exist yet; run the summarize step first")
}

plot_data <- dbGetQuery(
    con,
    "
    SELECT
      CAST(FLOOR(seconds_since_midnight / 60) * 60 AS DOUBLE) AS minute_of_day,
      AVG(vector_magnitude) AS mean_vector_magnitude
    FROM movement_intensity
    GROUP BY 1
    ORDER BY 1 ASC
  "
)

if (nrow(plot_data) == 0) {
    stop("movement_intensity table is empty; nothing to plot")
}

to_time_label <- function(seconds_value) {
    total_seconds <- as.integer(round(seconds_value))
    hours <- total_seconds %/% 3600
    minutes <- (total_seconds %% 3600) %/% 60
    sprintf("%02d:%02d", hours, minutes)
}

x_ticks <- pretty(plot_data$minute_of_day)
x_ticks <- x_ticks[x_ticks >= min(plot_data$minute_of_day) & x_ticks <= max(plot_data$minute_of_day)]
x_labels <- vapply(x_ticks, to_time_label, character(1))

png(filename = output_png, width = 1200, height = 700, res = 144)
on.exit(dev.off(), add = TRUE)

par(mar = c(6, 5, 4, 2) + 0.1)
plot(
    x = plot_data$minute_of_day,
    y = plot_data$mean_vector_magnitude,
    type = "l",
    lwd = 2,
    col = "steelblue",
    xaxt = "n",
    xlab = "Time of day",
    ylab = "Mean vector magnitude",
    main = "Movement Intensity Time Series"
)
axis(side = 1, at = x_ticks, labels = x_labels)
grid(nx = NA, ny = NULL, col = "gray85", lty = "dotted")
lines(plot_data$minute_of_day, plot_data$mean_vector_magnitude, col = "steelblue", lwd = 2)

cat(sprintf("OUTPUT_PNG=%s\n", output_png))
