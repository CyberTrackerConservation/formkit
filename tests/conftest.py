from pathlib import Path

import pytest

from formkit.repo import discover_forms

REPO_ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture(scope="session")
def repo_root() -> Path:
    return REPO_ROOT


def pytest_generate_tests(metafunc):
    """Parametrize any test taking a `form` argument over every form in the repo."""
    if "form" in metafunc.fixturenames:
        forms = discover_forms(REPO_ROOT)
        metafunc.parametrize("form", forms, ids=[f.id for f in forms])
