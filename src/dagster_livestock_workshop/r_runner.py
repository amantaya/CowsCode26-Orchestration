from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Iterable


def run_r_script(script_path: str | Path, args: Iterable[str] | None = None, timeout_seconds: int = 120) -> str:
    """Run an R script through Rscript and return stdout."""
    script = str(script_path)
    arg_list = list(args or [])

    try:
        completed = subprocess.run(
            ["Rscript", script, *arg_list],
            check=True,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(
            "Rscript executable not found. Install R and ensure Rscript is on PATH."
        ) from exc
    except subprocess.CalledProcessError as exc:
        raise RuntimeError(
            f"R script failed with exit code {exc.returncode}: {exc.stderr.strip()}"
        ) from exc

    return completed.stdout.strip()
