from pathlib import Path

from dagster_livestock_workshop.assets import _find_accelerometer_files


def test_find_accelerometer_files_finds_csvs(tmp_path: Path) -> None:
    (tmp_path / "DATA-001.CSV").write_text("time,ax,ay,az\n1,1,2,3\n", encoding="utf-8")
    (tmp_path / "DATA-002.csv").write_text("time,ax,ay,az\n2,4,5,6\n", encoding="utf-8")
    (tmp_path / "notes.txt").write_text("ignore me", encoding="utf-8")

    found = _find_accelerometer_files(tmp_path)

    assert [path.name for path in found] == ["DATA-001.CSV", "DATA-002.csv"]
