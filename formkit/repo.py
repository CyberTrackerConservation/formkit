"""Repository layout.

    forms/<name>/          one self-contained form: form.xlsx, *.qml screens, media/
    build/<name>/          finalized form.xlsx + flat media (generated)

Every form carries its own copy of its screens. Nothing is shared between
forms, so customizing one can never break another.
"""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

FORM_FILE = "form.xlsx"
MEDIA_DIR = "media"
FORMS_DIR = "forms"
BUILD_DIR = "build"


class RepoError(Exception):
    """Raised when the repository layout is not what we expect."""


def find_root(start: Path | None = None) -> Path:
    """Locate the repository root.

    Honors FORMKIT_ROOT, then walks up from *start* (default: cwd) looking for a
    folder containing forms/, then falls back to the folder containing this package.
    """
    env = os.environ.get("FORMKIT_ROOT")
    if env:
        return Path(env).resolve()

    here = (start or Path.cwd()).resolve()
    for candidate in (here, *here.parents):
        if (candidate / FORMS_DIR).is_dir():
            return candidate

    package_parent = Path(__file__).resolve().parents[1]
    if (package_parent / FORMS_DIR).is_dir():
        return package_parent

    raise RepoError(f"Could not find a formkit repository from {here}. Expected a folder containing '{FORMS_DIR}/'.")


@dataclass(frozen=True)
class Form:
    """One form folder: forms/<name>/."""

    root: Path
    name: str

    @property
    def id(self) -> str:
        return self.name

    @property
    def dir(self) -> Path:
        return self.root / FORMS_DIR / self.name

    @property
    def xlsx(self) -> Path:
        return self.dir / FORM_FILE

    @property
    def media_dir(self) -> Path:
        return self.dir / MEDIA_DIR

    def build_dir(self, build_root: Path | None = None) -> Path:
        return (build_root or self.root / BUILD_DIR) / self.name

    def resolve_qml(self, filename: str) -> Path:
        """A QML file named in the spreadsheet lives in the form folder itself."""
        candidate = self.dir / filename
        if candidate.is_file():
            return candidate
        raise FileNotFoundError(f"{filename} not found in {self.dir}")

    def media_files(self) -> list[Path]:
        """Files to ship alongside the form. Flat: subfolders and dotfiles are ignored."""
        if not self.media_dir.is_dir():
            return []
        return sorted(p for p in self.media_dir.iterdir() if p.is_file() and not p.name.startswith("."))


def discover_forms(root: Path) -> list[Form]:
    """Every forms/<name>/ folder containing a form.xlsx."""
    forms_dir = root / FORMS_DIR
    if not forms_dir.is_dir():
        return []
    return [Form(root, p.name) for p in sorted(forms_dir.iterdir()) if p.is_dir() and (p / FORM_FILE).is_file()]


def resolve_form(root: Path, spec: str) -> Form:
    """Accept a form name, or a path to its folder or its form.xlsx."""
    spec = spec.strip().rstrip("/")
    if (root / FORMS_DIR / spec / FORM_FILE).is_file() and "/" not in spec:
        return Form(root, spec)

    path = Path(spec).resolve()
    if path.is_file() and path.name == FORM_FILE:
        path = path.parent
    if path.is_dir() and (path / FORM_FILE).is_file() and path.parent == (root / FORMS_DIR).resolve():
        return Form(root, path.name)

    available = ", ".join(f.id for f in discover_forms(root)) or "none"
    raise RepoError(f"Unknown form '{spec}'. Available forms: {available}")
