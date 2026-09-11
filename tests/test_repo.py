"""Layout rules: discovery, form names, and screens living inside the form folder."""

from pathlib import Path

import pytest
from openpyxl import Workbook

from formkit.build import BuildError, build_form, qt_compress, qt_decompress
from formkit.cli import main
from formkit.repo import Form, RepoError, discover_forms, resolve_form


def _write_form(path: Path, qml_names: list[str]) -> None:
    wb = Workbook()
    ws = wb.active
    ws.title = "survey"
    ws.append(["type", "name", "label", "bind::ct:content.qmlFile"])
    for i, name in enumerate(qml_names):
        ws.append(["text", f"f{i}", f"Field {i}", name])
    settings = wb.create_sheet("settings")
    settings.append(["namespaces"])
    settings.append(['ct="http://cybertracker.org/xforms"'])
    path.parent.mkdir(parents=True, exist_ok=True)
    wb.save(path)


@pytest.fixture
def fake_repo(tmp_path: Path) -> Path:
    one = tmp_path / "forms" / "one"
    _write_form(one / "form.xlsx", ["title.qml", "collect.qml"])
    (one / "title.qml").write_text("one title")
    (one / "collect.qml").write_text("one collect")
    (one / "media").mkdir()
    (one / "media" / "icon.png").write_bytes(b"png")
    (one / "media" / ".DS_Store").write_bytes(b"junk")
    (tmp_path / "forms" / "two").mkdir()  # no form.xlsx, must be ignored
    return tmp_path


def test_qt_compress_roundtrip():
    data = "import QtQuick\nItem {}\n".encode()
    packed = qt_compress(data)
    assert packed[:4] == len(data).to_bytes(4, "big")
    assert qt_decompress(packed) == data


def test_discovery_and_names(fake_repo):
    forms = discover_forms(fake_repo)
    assert [f.id for f in forms] == ["one"]
    assert resolve_form(fake_repo, "one") == forms[0]
    assert resolve_form(fake_repo, str(fake_repo / "forms" / "one")) == forms[0]
    assert resolve_form(fake_repo, str(fake_repo / "forms" / "one" / "form.xlsx")) == forms[0]
    with pytest.raises(RepoError):
        resolve_form(fake_repo, "missing")


def test_screens_come_from_the_form_folder_only(fake_repo):
    form = Form(fake_repo, "one")
    assert form.resolve_qml("title.qml") == form.dir / "title.qml"
    with pytest.raises(FileNotFoundError):
        form.resolve_qml("nope.qml")


def test_build_embeds_own_screens_and_skips_dotfiles(fake_repo):
    form = Form(fake_repo, "one")
    result = build_form(form, validate=False, log=lambda _: None)
    assert result.output_dir == fake_repo / "build" / "one"
    assert {k: v.read_text() for k, v in result.qml.items()} == {"title.qml": "one title", "collect.qml": "one collect"}
    assert result.media == ["icon.png"]


def test_missing_qml_is_an_error(fake_repo):
    _write_form(fake_repo / "forms" / "bad" / "form.xlsx", ["ghost.qml"])
    with pytest.raises(BuildError, match="ghost.qml"):
        build_form(Form(fake_repo, "bad"), validate=False, log=lambda _: None)


def test_cli_list_and_build(fake_repo, capsys):
    assert main(["--root", str(fake_repo), "list"]) == 0
    assert "one" in capsys.readouterr().out
    assert main(["--root", str(fake_repo), "build", "one", "--no-validate", "-q"]) == 0
    assert (fake_repo / "build" / "one" / "form.xlsx").is_file()
    assert main(["--root", str(fake_repo), "build", "missing", "--no-validate"]) == 1
