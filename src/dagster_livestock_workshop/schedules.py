from __future__ import annotations

import hashlib
import json
from pathlib import Path

from dagster import (
    DefaultSensorStatus,
    RunRequest,
    ScheduleDefinition,
    SensorEvaluationContext,
    SkipReason,
    define_asset_job,
    sensor,
)

from .assets import ACCELEROMETER_INGEST_DIR, _find_accelerometer_files


def _ingest_csv_snapshot(root: Path = ACCELEROMETER_INGEST_DIR) -> dict[str, int]:
    """Return relative CSV file paths and mtimes for sensor change detection."""
    csv_files = _find_accelerometer_files(root)
    return {str(path.relative_to(root)): path.stat().st_mtime_ns for path in csv_files}


def _sensor_run_key(changed_files: list[str]) -> str:
    joined = "|".join(changed_files)
    digest = hashlib.sha256(joined.encode("utf-8")).hexdigest()[:12]
    return f"ingest-{len(changed_files)}-{digest}"


accelerometer_ingest_job = define_asset_job(
    "accelerometer_ingest_job",
    selection=[
        "accelerometer_data_to_duckdb",
        "movement_intensity",
        "movement_intensity_plot",
    ],
)

weather_refresh_job = define_asset_job(
    "weather_refresh_job",
    selection=["weather_api_demo"],
)

weather_refresh_schedule = ScheduleDefinition(
    job=weather_refresh_job,
    cron_schedule="* * * * *",
    execution_timezone="UTC",
)


@sensor(
    job=accelerometer_ingest_job,
    minimum_interval_seconds=5,
    default_status=DefaultSensorStatus.STOPPED,
)
def ingest_csv_sensor(context: SensorEvaluationContext):
    """Trigger accelerometer pipeline when CSV files appear or are updated in Ingest."""
    current_snapshot = _ingest_csv_snapshot()
    previous_snapshot = json.loads(context.cursor) if context.cursor else {}

    changed_files = sorted(
        file_name
        for file_name, mtime_ns in current_snapshot.items()
        if previous_snapshot.get(file_name) != mtime_ns
    )

    context.update_cursor(json.dumps(current_snapshot, sort_keys=True))

    if not current_snapshot:
        return SkipReason("No CSV files found in data/Ingest.")

    if not changed_files:
        return SkipReason("No new or updated CSV files in data/Ingest.")

    return RunRequest(
        run_key=_sensor_run_key(changed_files),
        tags={
            "sensor": "ingest_csv_sensor",
            "changed_file_count": str(len(changed_files)),
        },
    )
