from pathlib import Path

from dagster import AssetExecutionContext, MaterializeResult, asset

from .r_runner import run_r_script

REPO_ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = REPO_ROOT / "data"
SCRIPTS_DIR = REPO_ROOT / "scripts"


def _find_accelerometer_files(root: Path | None = None) -> list[Path]:
    """Return all accelerometer CSV files beneath the provided directory."""
    data_root = root or DATA_DIR
    return sorted(
        path
        for path in data_root.rglob("*")
        if path.is_file() and path.suffix.lower() == ".csv"
    )


@asset
def accelerometer_data_to_duckdb(context: AssetExecutionContext) -> MaterializeResult:
    """Read accelerometer CSV files and write them to a DuckDB table."""
    data_dir = DATA_DIR / "Steer327_060916"
    output_db = DATA_DIR / "accelerometer.duckdb"
    script_path = SCRIPTS_DIR / "write_data_duckdb.R"

    csv_files = _find_accelerometer_files(data_dir)
    if not csv_files:
        raise RuntimeError(f"No accelerometer CSV files found in {data_dir}")

    stdout = run_r_script(script_path, [str(data_dir), str(output_db), "all"])
    context.log.info("R output: %s", stdout)

    return MaterializeResult(
        metadata={
            "input_dir": str(data_dir),
            "input_files": len(csv_files),
            "output_db": str(output_db),
            "r_stdout": stdout,
        }
    )


@asset(deps=[accelerometer_data_to_duckdb])
def movement_intensity(context: AssetExecutionContext) -> MaterializeResult:
    """Calculate movement-intensity values from the ingested accelerometer data."""
    data_dir = DATA_DIR / "Steer327_060916"
    output_db = DATA_DIR / "accelerometer.duckdb"
    script_path = SCRIPTS_DIR / "write_data_duckdb.R"

    stdout = run_r_script(script_path, [str(data_dir), str(output_db), "summarize"])
    context.log.info("R output: %s", stdout)

    return MaterializeResult(
        metadata={
            "input_dir": str(data_dir),
            "output_db": str(output_db),
            "r_stdout": stdout,
        }
    )


@asset
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


@asset(deps=[weather_api_demo])
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
