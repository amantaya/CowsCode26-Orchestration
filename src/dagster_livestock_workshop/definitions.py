from dagster import Definitions

from .assets import (
    accelerometer_data_to_duckdb,
    movement_intensity,
    weather_api_demo,
)
from .schedules import (
    accelerometer_ingest_job,
    ingest_csv_sensor,
    weather_refresh_job,
    weather_refresh_schedule,
)

defs = Definitions(
    assets=[
        accelerometer_data_to_duckdb,
        movement_intensity,
        weather_api_demo,
    ],
    jobs=[accelerometer_ingest_job, weather_refresh_job],
    schedules=[weather_refresh_schedule],
    sensors=[ingest_csv_sensor],
)
