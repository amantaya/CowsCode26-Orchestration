from __future__ import annotations

import argparse
from pathlib import Path

from dagster_livestock_workshop.r_runner import run_r_script


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run an R script through Python subprocess (Rscript)."
    )
    parser.add_argument("script", help="Path to the R script")
    parser.add_argument(
        "script_args",
        nargs="*",
        help="Optional arguments passed to the R script",
    )
    args = parser.parse_args()

    output = run_r_script(Path(args.script), args.script_args)
    print(output)


if __name__ == "__main__":
    main()
