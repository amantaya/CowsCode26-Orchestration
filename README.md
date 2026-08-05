# Dagster Fundamentals Workshop (Precision Livestock Tech)

This repository is a complete starter kit for a **1-hour Dagster workshop** aimed at R-first research teams.

## What is Included

- Dagster scaffold with assets, jobs, and schedules
- API materialization demo asset
- Scheduled API ingestion demo asset
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
│  └─ summarize_livestock_api.R
├─ slides/
│  └─ workshop.qmd
├─ run_r_subprocess.py
├─ _quarto.yml
└─ .github/workflows/publish-quarto.yml
```

## Prerequisites

1. Python 3.10+
2. R with `Rscript` available on PATH
3. R package: `jsonlite`
4. Quarto CLI (for local slide rendering)

Install R package:

```r
install.packages("jsonlite")
```

## Python Setup

### PowerShell

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install -e .
```

## Start Dagster for Live Demo

```powershell
dagster dev -m dagster_livestock_workshop.definitions
```

Dagster UI typically opens at `http://127.0.0.1:3000`.

## Live Demo Plan

### Demo 1: Materialize a Simple API Asset

1. In Dagster UI, open asset `livestock_reference_api`.
2. Click **Materialize**.
3. Show metadata and output file: `data/livestock_reference_api.json`.

### Demo 2: Execute R Script via Dagster Asset

1. Open asset `r_postprocess_demo`.
2. Materialize it (it depends on `livestock_reference_api`).
3. Show generated file: `data/livestock_reference_summary.csv`.
4. Explain Python -> subprocess -> `Rscript` bridge in `r_runner.py`.

### Demo 3: Scheduled API Call

1. Open schedule `daily_livestock_schedule` in Dagster UI.
2. Enable the schedule.
3. Trigger a manual tick in the UI for immediate demonstration.
4. Show output file: `data/scheduled_livestock_api.json`.

## Standalone R Subprocess Script

You can run any R script through Python:

```powershell
python run_r_subprocess.py scripts/summarize_livestock_api.R data/livestock_reference_api.json data/livestock_reference_summary.csv
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
- 15 min: Materialize API asset
- 10 min: R subprocess integration
- 10 min: Schedule and automation
- 10 min: Extension ideas for livestock research
- 5 min: Q&A
