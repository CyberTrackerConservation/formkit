# Form kit: guide for AI assistants

This repo builds CyberTracker survey forms. Read this before changing anything.

## Map

- `forms/<name>/` is one complete form: `form.xlsx`, the three QML screens it names (`title.qml`, `metadata.qml`, `collect.qml`), `media/` with its icons, and a `README.md` that says what the form records and which rows, columns and settings its screens depend on.
- Forms share nothing. Each carries its own copy of its screens. Changing a file inside one form never affects another. Do not introduce shared folders or templates.
- `formkit/` is the build tool. `tests/` builds every form and checks the output.
- `build/` is generated. Never edit it, never commit it.

## Commands

```bash
source .venv/bin/activate          # or: python3 -m venv .venv && pip install -e ".[dev]"
formkit list                       # what exists
formkit dump <name>                # read a spreadsheet as Markdown. Do this before reasoning about a form.
formkit validate                   # static checks: screens exist, media exists, namespaces set
formkit build <name>               # embed screens, copy media, run pyxform + ODK Validate
pytest                             # run after any change to formkit/ or to a form
```

A change is done when `formkit build <name>` passes and `pytest` passes.

## Editing spreadsheets

`form.xlsx` is the source of truth. Edit it with `openpyxl` (already installed), keeping the sheet and column names intact. Do not use the KoBoToolbox form builder on these forms; it strips the `bind::ct:` columns.

Rules that apply to every form:

- Keep the housekeeping rows: `survey_id`, `track_file`, `type`, `datetime`, `location`. The screens depend on them.
- Keep the `bind::ct:content.qmlFile` column and the rows that reference `title.qml`, `metadata.qml` and `collect.qml`.
- Keep `namespaces` on the `settings` sheet set to `ct="http://cybertracker.org/xforms"`.
- Field `name` values are XlsForm identifiers: lowercase, underscores, no spaces.
- Choice `name` values must be unique within a list.
- Every value in a `media::image` column must be a file in `media/`.

Form-specific rules are in `forms/<name>/README.md`. Read it for the form you are editing.

## Editing screens

The screens are QML and read the spreadsheet in two different styles:

- `talk-sheep` finds fields by tag. Fields carry `metadata` or `fill` in the `bind::ct:tag.timeline` column, and the screens call `form.buildTaggedFields(...)`. Adding a field is a spreadsheet change only.
- `icon-wildlife` names fields directly. `metadata.qml` lists the metadata field names in `filterFieldUids`, derives `mission_id` from the site, and skips to `observation_category`. `title.qml` uses `wcs.svg` as a watermark. When a copy of this form changes those fields, change those lines too.

Screens cannot be run here. Behaviour on the device is verified with the CyberTracker desktop simulator from https://cybertrackerwiki.org/xlsform/download. Say so when a change touches QML.

## Icons

Do not draw icons. The library at https://wildlifeicons.org publishes its index at https://wildlifeicons.org/icons.json (fields: `filename`, `key`, `source`, `name`, `tags`). Search it by name or tag, download `https://wildlifeicons.org/icons/<filename>` into the form's `media/` folder, and put the file name in `media::image`. Prefer SVG. Icons under `Aerial/` were drawn for the aerial form.

## Creating a new form

1. Copy the closest existing form folder under `forms/` to a new kebab-case name. Copy the whole folder, screens included.
2. Update the spreadsheet: metadata fields, observation fields, choice lists, settings such as `summaryText` and `bind::ct:icon`.
3. Update the screens if the copied form names fields directly (see above).
4. Add icons to `media/` and reference them.
5. Write the form's `README.md`: what it records, which lists a project is expected to edit, which rows and settings the screens depend on.
6. `formkit build <name>` until clean, then `pytest`.
