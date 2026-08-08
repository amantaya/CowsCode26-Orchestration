from dagster import Definitions

from .assets import (
    livestock_reference_api,
    r_postprocess_demo,
    scheduled_livestock_api,
    weather_api_demo,
)
from .schedules import daily_livestock_schedule, scheduled_livestock_job

defs = Definitions(
    assets=[
        livestock_reference_api,
        scheduled_livestock_api,
        r_postprocess_demo,
        weather_api_demo,
    ],
    jobs=[scheduled_livestock_job],
    schedules=[daily_livestock_schedule],
)
