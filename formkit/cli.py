"""Command line entry point: formkit list | build | validate | dump."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import __version__
from .build import BuildError, build_form
from .repo import Form, RepoError, discover_forms, find_root, resolve_form
from .validate import ValidationError, check_form


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="formkit", description="Build CyberTracker survey forms.")
    parser.add_argument("--version", action="version", version=f"formkit {__version__}")
    parser.add_argument("--root", type=Path, help="repository root (default: auto-detect)")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("list", help="list forms")
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("build", help="build forms into build/ (default: all)")
    p.add_argument("forms", nargs="*", help="form names like icon-wildlife, or paths")
    p.add_argument("--build-dir", type=Path, help="output root (default: <root>/build)")
    p.add_argument("--no-validate", action="store_true", help="skip pyxform validation")
    p.add_argument("-q", "--quiet", action="store_true")
    p.set_defaults(func=cmd_build)

    p = sub.add_parser("validate", help="check forms without building (default: all)")
    p.add_argument("forms", nargs="*")
    p.set_defaults(func=cmd_validate)

    p = sub.add_parser("dump", help="print a form's sheets as Markdown tables")
    p.add_argument("form", help="form name like icon-wildlife, or a path to an .xlsx")
    p.add_argument("--sheet", action="append", help="only this sheet (repeatable)")
    p.add_argument("--built", action="store_true", help="dump the built output instead of the source")
    p.set_defaults(func=cmd_dump)

    args = parser.parse_args(argv)
    try:
        root = args.root.resolve() if args.root else find_root()
        return args.func(root, args)
    except (RepoError, BuildError, ValidationError, FileNotFoundError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 1


def _select_forms(root: Path, specs: list[str]) -> list[Form]:
    if specs:
        return [resolve_form(root, s) for s in specs]
    forms = discover_forms(root)
    if not forms:
        raise RepoError(f"no forms found under {root / 'forms'}")
    return forms


def cmd_list(root: Path, args) -> int:
    print(f"root: {root}")
    print("forms:")
    for form in discover_forms(root):
        print(f"  {form.id}")
    return 0


def cmd_build(root: Path, args) -> int:
    log = (lambda _msg: None) if args.quiet else print
    failed: list[str] = []
    for form in _select_forms(root, args.forms):
        try:
            build_form(form, build_root=args.build_dir, validate=not args.no_validate, log=log)
        except (BuildError, ValidationError, FileNotFoundError) as e:
            failed.append(form.id)
            print(f"error: {form.id}: {e}", file=sys.stderr)
    if failed:
        print(f"failed: {', '.join(failed)}", file=sys.stderr)
        return 1
    return 0


def cmd_validate(root: Path, args) -> int:
    bad = 0
    for form in _select_forms(root, args.forms):
        problems = check_form(form)
        status = "ok" if not problems else f"{len(problems)} problem(s)"
        print(f"{form.id}: {status}")
        for problem in problems:
            print(f"  - {problem}")
        bad += bool(problems)
    return 1 if bad else 0


def cmd_dump(root: Path, args) -> int:
    from .dump import dump_xlsx

    spec = args.form
    if spec.endswith(".xlsx") and Path(spec).is_file():
        path = Path(spec)
    else:
        form = resolve_form(root, spec)
        path = form.build_dir() / form.xlsx.name if args.built else form.xlsx
        if not path.is_file():
            raise FileNotFoundError(f"{path} does not exist" + (" (run `formkit build` first)" if args.built else ""))
    print(f"# {path}\n")
    print(dump_xlsx(path, args.sheet))
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
