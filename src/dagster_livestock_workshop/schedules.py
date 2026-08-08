from dagster import ScheduleDefinition, define_asset_job

weather_refresh_job = define_asset_job(
    "weather_refresh_job",
    selection=["weather_api_demo"],
)

weather_refresh_schedule = ScheduleDefinition(
    job=weather_refresh_job,
    cron_schedule="* * * * *",
    execution_timezone="UTC",
)
