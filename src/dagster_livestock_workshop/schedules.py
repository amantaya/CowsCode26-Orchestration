from dagster import ScheduleDefinition, define_asset_job

scheduled_livestock_job = define_asset_job(
    "scheduled_livestock_job",
    selection=["scheduled_livestock_api"],
)

daily_livestock_schedule = ScheduleDefinition(
    job=scheduled_livestock_job,
    cron_schedule="0 9 * * *",
    execution_timezone="UTC",
)
