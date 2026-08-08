# Dagster Fundamentals Workshop (Precision Livestock Tech)

## Course Content

The workshop slides are available here: https://amantaya.github.io/CowsCode26-Orchestration/slides/workshop.html#/title-slide

This repository is a complete starter kit for a **1-hour workshop** aimed at R-first research teams working with Precision Livestock Technology (PLT).

## What is Included

- Dagster scaffold with assets, jobs, schedules, and a file-watching sensor
- Accelerometer CSV ingestion pipeline (DuckDB-backed)
- Movement-intensity summarisation and PNG plot generation
- Weather API materialization demo asset
- Python helper to run R scripts through subprocess (`Rscript`)
- Quarto slideshow source for workshop delivery
- GitHub Pages workflow to publish workshop content

## Repository Layout

```text
.
├─ src/dagster_livestock_workshop/
│  ├─ assets.py
│  ├─ schedules.py
│  ├─ definitions.py
│  └─ r_runner.py
├─ scripts/
│  ├─ write_data_duckdb.R
│  ├─ plot_movement_intensity.R
│  ├─ fetch_weather_open_meteo.R
│  └─ summarize_weather_open_meteo.R
├─ data/
│  └─ Ingest/          ← drop accelerometer CSVs here
├─ slides/
│  └─ workshop.qmd
├─ run_r_subprocess.py
├─ _quarto.yml
└─ .github/workflows/publish-quarto.yml
```

## Prerequisites

1. Python 3.10+
2. R with `Rscript` available on PATH
3. R packages: `duckdb`, `DBI`
4. Quarto CLI (for local slide rendering)
5. UV package manager

Install R packages:

```r
install.packages(c("duckdb", "DBI"))
```

Install UV (PowerShell):

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

## Environment + Dependencies (UV)

### PowerShell

On Windows:

```powershell
uv venv
.\.venv\Scripts\Activate.ps1
uv sync
```

On Mac/Linux:

```shell
uv venv
source .venv/bin/activate
uv sync
```

## Dagster Install and Verification

Dagster is already declared in `pyproject.toml` and is installed by `uv sync`.

To verify:

```powershell
uv run dagster --version
```

Optional (if you want to add/upgrade Dagster packages explicitly):

```powershell
uv add dagster dagster-webserver
uv sync
```

## Start Dagster for Live Demo

```powershell
uv run dagster dev -m dagster_livestock_workshop.definitions
```

Dagster UI typically opens at `http://127.0.0.1:3000`.

## Live Demo Plan

### Demo 1: Ingest Accelerometer Data to DuckDB

1. Copy accelerometer CSV files into `data/Ingest/`.
2. In Dagster UI, open asset `accelerometer_data_to_duckdb`.
3. Click **Materialize**.
4. Show metadata and output file: `data/accelerometer.duckdb`.

### Demo 2: Calculate and Plot Movement Intensity

1. Open asset `movement_intensity` (depends on `accelerometer_data_to_duckdb`).
2. Materialize it — runs `write_data_duckdb.R` in summarize mode.
3. Open asset `movement_intensity_plot` (depends on `movement_intensity`).
4. Materialize it — runs `plot_movement_intensity.R` and writes `data/movement_intensity.png`.
5. Explain the Python → subprocess → `Rscript` bridge in `r_runner.py`.

### Demo 3: Fetch Weather Data from Open-Meteo

1. In Dagster UI, open asset `weather_api_demo`.
2. Click **Materialize**.
3. Show metadata and output file: `data/weather_open_meteo.csv`.

### Demo 4: Sensor-Driven Pipeline

1. Open sensor `ingest_csv_sensor` in Dagster UI.
2. Enable the sensor (default status is **STOPPED**).
3. Drop a new CSV file into `data/Ingest/` and observe the sensor trigger `accelerometer_ingest_job` automatically.

### Demo 5: Scheduled Weather Refresh

1. Open schedule `weather_refresh_schedule` in Dagster UI.
2. Enable the schedule (runs `weather_refresh_job` every minute).
3. Trigger a manual tick in the UI for immediate demonstration.

## Standalone R Subprocess Script

You can run any R script through Python directly:

```powershell
# Ingest CSVs into DuckDB
uv run python run_r_subprocess.py scripts/write_data_duckdb.R data/Ingest data/accelerometer.duckdb all

# Summarize into movement_intensity table
uv run python run_r_subprocess.py scripts/write_data_duckdb.R data/Ingest data/accelerometer.duckdb summarize

# Generate movement intensity plot
uv run python run_r_subprocess.py scripts/plot_movement_intensity.R data/accelerometer.duckdb data/movement_intensity.png
```

## Quarto Slides

Local render:

```powershell
quarto render
```

Open:

- `docs/slides/workshop.html`

## Publish Slides to GitHub Pages

The workflow `.github/workflows/publish-quarto.yml` will:

1. Render Quarto files on pushes to `main`
2. Publish `docs/` to `gh-pages`

After first push, enable GitHub Pages in repository settings:

- Source: `Deploy from a branch`
- Branch: `gh-pages` (root)

## Suggested Workshop Timing (1 Hour)

- 10 min: Orchestration foundations and Dagster concepts
- 15 min: Ingest accelerometer CSVs to DuckDB
- 10 min: Movement-intensity summary and plot
- 10 min: Sensor-driven pipeline automation
- 10 min: Scheduled weather API refresh
- 5 min: Q&A

## First-Time Setup Checklist

Use this checklist to go from clone to first successful Dagster run.

1. Open PowerShell in the repository root.
2. Verify Python is available:

```powershell
python --version
```

3. Install UV (skip if already installed):

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

4. Create and activate the virtual environment:

```powershell
uv venv
.\.venv\Scripts\Activate.ps1
```

5. Install project dependencies (including Dagster):

```powershell
uv sync
```

6. Verify Dagster is installed:

```powershell
uv run dagster --version
```

7. Verify R and required packages:

```powershell
Rscript --version
Rscript -e "if (!requireNamespace('duckdb', quietly=TRUE)) install.packages('duckdb', repos='https://cloud.r-project.org')"
Rscript -e "if (!requireNamespace('DBI', quietly=TRUE)) install.packages('DBI', repos='https://cloud.r-project.org')"
```

If `Rscript` is not recognized, add your R x64 bin folder to PATH (example):

```powershell
$target = 'C:\Program Files\R\R-4.5.2\bin\x64'
$env:Path = "$target;$env:Path"
[Environment]::SetEnvironmentVariable('Path', "$target;" + [Environment]::GetEnvironmentVariable('Path','User'), 'User')
```

Then open a new terminal and re-run `Rscript --version`.

8. Start Dagster:

```powershell
uv run dagster dev -m dagster_livestock_workshop.definitions
```

9. Copy accelerometer CSV files into `data/Ingest/` and materialize `accelerometer_data_to_duckdb`.
10. Materialize `movement_intensity` and then `movement_intensity_plot` and confirm `data/movement_intensity.png` exists.
