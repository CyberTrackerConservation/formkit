# Form kit

Ready-made survey forms for [CyberTracker](https://cybertracker.org), built on the [XlsForm](https://xlsform.org) standard and the [CyberTracker XlsForm extensions](https://cybertrackerwiki.org/xlsform/). Each form is a complete data capture experience that a project can copy, customize, and deploy to [KoBoToolbox](https://kobotoolbox.org), [ODK Central](https://getodk.org) or [Survey123](https://survey123.arcgis.com).

How the system works and how to set it up with KoBoToolbox is on the wiki: [cybertrackerwiki.org/xlsform/formkit](https://cybertrackerwiki.org/xlsform/formkit). The forms themselves are documented here, one README per form.

## Forms

| Form | Designed for | How data is entered |
| ---- | ------------ | ------------------- |
| [icon-wildlife](forms/icon-wildlife/) | Rapid counts from a moving aircraft or vehicle, on a tablet | Tap large icons. Location is captured at the moment of the tap. |
| [talk-sheep](forms/talk-sheep/) | Hands-free, eyes-free counts, for example along a transect | Speak. The app records, transcribes and parses each utterance into a record. |

Each form's README has screenshots, what it records, which lists a project is expected to change, and which rows and settings its screens depend on.

> **Note:** the data model works with every XlsForm backend, but CyberTracker is required on the device. The custom screens are CyberTracker extensions.

## Layout

```
forms/<name>/
  form.xlsx          what is collected: fields, choice lists, settings
  title.qml          home screen
  metadata.qml       session setup
  collect.qml        the capture screen (icon grid, voice recorder, ...)
  media/             icons and images named in the spreadsheet
  README.md          what the form records and what to change
build/<name>/        generated: finalized form.xlsx + flat media, ready to upload
formkit/             the build tool (Python package, `formkit` command)
tests/               builds every form and checks the output
```

Every form is self-contained on purpose. It carries its own copy of its screens, so copying a form and customizing it can never break another one. The spreadsheet names its screens in the `bind::ct:content.qmlFile` column and the build embeds them.

## Quick start

```bash
git clone https://github.com/CyberTrackerConservation/formkit.git
cd formkit
python3 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"

formkit list                      # forms in the repo
formkit build                     # build every form into build/
formkit build icon-wildlife       # build one form
formkit validate                  # static checks without building
formkit dump talk-sheep           # print the spreadsheet as Markdown tables
pytest                            # build everything and check it
```

The build embeds the screens into the spreadsheet (compressed and base64-encoded into a `bind::ct:content.qmlBase64z` column), copies the media, and validates the result with [pyxform](https://github.com/XLSForm/pyxform). With `java` on the PATH, pyxform also runs ODK Validate.

## Deploying

Upload `build/<name>/form.xlsx` and every other file in that folder to your backend. The wiki walks through the whole path for KoBoToolbox with screenshots, from creating the project to seeing data arrive: [cybertrackerwiki.org/xlsform/formkit](https://cybertrackerwiki.org/xlsform/formkit#deploying-to-kobotoolbox).

Do not edit the form in a backend's form builder. Builders do not show the CyberTracker columns and saving from one removes them. Edit the spreadsheet, rebuild, and re-upload.

## Making your own form

1. Copy the closest existing form folder under `forms/` and give it a new name.
2. Open `form.xlsx` and change the choice lists and fields. The form's README says which rows and columns its screens depend on.
3. Put icons in `media/` and name them in the `media::image` column. Icons come from [wildlifeicons.org](https://wildlifeicons.org).
4. Change the screens if the form needs different behaviour. They are ordinary QML files in the same folder.
5. Run `formkit build <name>` and fix anything it reports.

An AI coding assistant can do steps 2 to 5 from a description. See [Using an AI assistant](#using-an-ai-assistant).

## Using an AI assistant

The repository is arranged so that an assistant such as Claude Code can create or change a form from a description. [CLAUDE.md](CLAUDE.md) tells it how the repo works, each form's README says what its screens depend on, and `formkit build` tells it whether the result is valid.

Open the repo in the assistant and describe what you need, for example:

> Copy icon-wildlife to a new form called icon-marine for counting turtles, dugongs, boats and nets from a light aircraft. Metadata should be aircraft, pilot, two observers and transect number. Find icons on wildlifeicons.org. Build it and tell me what to upload.

> In talk-sheep, add a field for group size and an alias so that "herd of" is understood as group size. Rebuild and check it validates.

The assistant checks its work with `formkit build`, which fails on a missing screen or media file and runs pyxform and ODK Validate on the result. It cannot run the screens. Behaviour on the device is checked with the [desktop simulator](https://cybertrackerwiki.org/xlsform/download).

## History

This repository merges the former `aerialsurvey` and `talksurvey` repositories. MIT licensed. Built on CyberTracker, XlsForm, KoBoToolbox, ODK and Survey123, with thanks to the field teams who tested these forms in the air and on the ground.
