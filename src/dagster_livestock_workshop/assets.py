import json
from datetime import datetime, timezone
from pathlib import Path

import requests
from dagster import AssetExecutionContext, MaterializeResult, asset

from .r_runner import run_r_script

REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = REPO_ROOT / "data"
SCRIPTS_DIR = REPO_ROOT / "scripts"


def _write_json(payload: dict, file_name: str) -> Path:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    output_path = DATA_DIR / file_name
    output_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return output_path


@asset(group_name="api_demo")
def weather_api_demo(context: AssetExecutionContext) -> MaterializeResult:
    """Fetch a weather snapshot from Open-Meteo without an API key."""
    output_path = DATA_DIR / "weather_open_meteo.csv"
    script_path = SCRIPTS_DIR / "fetch_weather_open_meteo.R"

    stdout = run_r_script(script_path, [str(output_path)])
    context.log.info("R output: %s", stdout)

    return MaterializeResult(
        metadata={
            "source": "https://open-meteo.com/",
            "output_csv": str(output_path),
            "r_stdout": stdout,
        }
    )


@asset(group_name="api_demo")
def livestock_reference_api(context: AssetExecutionContext) -> MaterializeResult:
    """Simple one-shot API materialization for live demo."""
    response = requests.get("https://httpbin.org/json", timeout=20)
    response.raise_for_status()
    payload = response.json()

    stamped = {
        "fetched_at_utc": datetime.now(timezone.utc).isoformat(),
        "source": "https://httpbin.org/json",
        "payload": payload,
    }
    output_path = _write_json(stamped, "livestock_reference_api.json")

    context.log.info("Saved API response to %s", output_path)
    return MaterializeResult(
        metadata={
            "recorded_at": stamped["fetched_at_utc"],
            "output_file": str(output_path),
        }
    )


@asset(group_name="api_demo")
def scheduled_livestock_api(context: AssetExecutionContext) -> MaterializeResult:
    """Asset that will be materialized by a schedule."""
    response = requests.get("https://httpbin.org/uuid", timeout=20)
    response.raise_for_status()
    payload = response.json()

    stamped = {
        "fetched_at_utc": datetime.now(timezone.utc).isoformat(),
        "source": "https://httpbin.org/uuid",
        "payload": payload,
    }
    output_path = _write_json(stamped, "scheduled_livestock_api.json")

    context.log.info("Saved scheduled API response to %s", output_path)
    return MaterializeResult(
        metadata={
            "recorded_at": stamped["fetched_at_utc"],
            "uuid": payload.get("uuid", "unknown"),
            "output_file": str(output_path),
        }
    )


@asset(group_name="api_demo", deps=[weather_api_demo])
def r_postprocess_demo(context: AssetExecutionContext) -> MaterializeResult:
    """Call an R script from Python to summarize the weather snapshot into CSV."""
    input_csv = DATA_DIR / "weather_open_meteo.csv"
    output_csv = DATA_DIR / "weather_open_meteo_summary.csv"
    script_path = SCRIPTS_DIR / "summarize_weather_open_meteo.R"

    stdout = run_r_script(script_path, [str(input_csv), str(output_csv)])
    context.log.info("R output: %s", stdout)

    return MaterializeResult(
        metadata={
            "input_csv": str(input_csv),
            "output_csv": str(output_csv),
            "r_stdout": stdout,
        }
    )
