# Talk survey

Hands-free, eyes-free data capture. The observer speaks; the device records, stamps the clip with a GPS location, transcribes it, and turns the transcript into a structured record. This form is a spoken count of bighorn sheep along a transect.

## How it works

1. **Listen.** During a session the app runs a voice recorder continuously. It waits in a *listening* state until it detects speech, then switches to *recording*. The GPS location and timestamp are captured the moment recording starts.
2. **Clip.** When the observer stops talking, the clip is saved as a `Voice` record with the audio file, duration, timestamp and location. A new empty record opens immediately.
3. **Transcribe.** Each clip is queued for transcription. The transcriber is given a speech prompt built from the command words plus the names, aliases and allowed values of every observation field, which biases recognition towards the vocabulary in use. The transcript is written to the `transcribe` field.
4. **Parse.** When transcription for a session completes, the timeline (hosted by `title.qml`) splits transcripts on the command words and writes one `Data` record per observation, each carrying the audio of the clip it came from. The correction command rewrites the previous observation instead of adding one. The clips that produced words are then deleted; a clip the transcriber heard nothing in is kept, with its audio, so it can be checked by ear (`bind::ct:timeline.deleteEmpty` = `no`).

Because transcription and parsing happen afterwards, the audio stays attached as evidence and a survey can be recorded fully offline.

Say: **"observation"** three bucks, two does, brushy, rolling, four hundred metres **"stop"**

## What it records

- **Per session:** monitoring unit (with an "other" fallback), light conditions, transect number.
- **Per observation:** counts of bucks, does, fawns and unidentified animals, vegetation, terrain, activity, distance in metres.

## Command words

| Setting | Value | Spoken meaning |
| ------- | ----- | -------------- |
| `bind::ct:timeline.commandStart` | `observation` | Begin a new observation |
| `bind::ct:timeline.commandStop` | `stop` | End the current observation |
| `bind::ct:timeline.commandError` | `correction` | Replace the previous observation |

Choose command words that are distinctive and unlikely to occur in normal dictation.

`bind::ct:timeline.deleteEmpty` is `no`: a clip whose transcription returns nothing stays as a `Voice` record. Set it to `yes` to delete such clips once their session is parsed.

## What a project is expected to change

- Lists on the `choices` sheet: `monitoring_unit`, `light`, `vegetation`, `terrain`, `activity`.
- Observation fields on the `survey` sheet: add a row, tag it `fill` in `bind::ct:tag.timeline`, and it appears on the prompt sheet and in the speech prompt automatically.
- Aliases in `label::alias` for the words your team actually says, for example `bucks` for `buck`.

The screens find fields by tag, so none of these changes touch QML.

## Files

| File | Attached to | Notes |
| ---- | ----------- | ----- |
| `form.xlsx` | | The XlsForm. Sheets: `survey`, `choices`, `settings`. |
| `title.qml` | `type` | Home screen. Lists sightings grouped by session, runs the timeline that parses completed sessions and deletes the clips it used, blocks **Submit** and **New survey** while transcription is running. Tapping the `Stop` record shows the track; other records open in the inspector. Uses the project icon as a watermark. |
| `metadata.qml` | `location` | Session setup. Edits every field tagged `metadata`, validates required ones, starts track logging, writes the `Start` record, jumps to the first field tagged `fill`. |
| `collect.qml` | the first field tagged `fill` | Runs the recorder, shows the prompt sheet listing every observation field and its allowed values, shows recorder status in the footer, saves `Voice` records, handles **Stop survey**. The home button leaves the project mid-session; reopening it returns here. |
| `media/icon.png` | | Project icon. |

## What the screens depend on

**survey sheet**

| Row | Type | Required columns |
| --- | ---- | ---------------- |
| `survey_id`, `track_file` | `text`, `file` (`parameters` = `format=geojson`) | `appearance` = `hidden` |
| `type` | `text` | `bind::ct:content.qmlFile` = `title.qml`, `header.hidden` and `footer.hidden` = `yes`, `content.frameWidth` = `0` |
| `datetime` | `start` | `appearance` = `hidden` |
| `location` | `geopoint` | `bind::ct:tag.timeline` = `metadata`, `bind::ct:content.qmlFile` = `metadata.qml`, same hidden header and footer |
| metadata fields | any | `bind::ct:tag.timeline` = `metadata` |
| observation fields | `integer`, `select_one`, `text` | `bind::ct:tag.timeline` = `fill`. The **first** one also carries `bind::ct:content.qmlFile` = `collect.qml` with hidden header and footer and `content.lines` = `no`. |
| `audio` | `audio` | `bind::ct:transcribeTo` = `transcribe` |
| `transcribe` | `text` | |

`label::alias` on the survey sheet lists alternative spoken forms of a field name.

**Languages.** KoBoToolbox reads `label::alias` as a language called `alias`, and since late 2026 it refuses a form that mixes translated and untranslated columns (`These columns are not translated: ...`). So in this form every label column carries a language: labels live in `label::English (en)`, never in a bare `label`, and `default_language` on the settings sheet is `English (en)`. The same rule means there is no `media::image` column on either sheet: KoBoToolbox would demand `media::image::English (en)`, and CyberTracker only reads an image column named exactly `media::image`. The project icon comes from `bind::ct:icon` on the settings sheet, which is unaffected.

**choices sheet**: columns `list_name`, `name`, `label::English (en)`, `label::alias`, `category`. Aliases go into the speech prompt; the prompt sheet shows the values.

**settings sheet**: `namespaces` = `ct="http://cybertracker.org/xforms"`, `bind::ct:icon`, `bind::ct:immersive` = `yes`, the three `bind::ct:timeline.command*` words, `bind::ct:timeline.deleteEmpty`, `bind::ct:trackFile` = `track_file`, `bind::ct:summaryText`, `bind::ct:locationTrackDistance`, `bind::ct:locationTrackInterval`, `default_language` = `English (en)`.

## Records

| `type`  | Created when | Contains |
| ------- | ------------ | -------- |
| `Start` | **Start survey** | Session metadata and starting location |
| `Voice` | Each utterance | Audio clip, location, timestamp, transcript. Deleted once parsed, unless the transcript was empty |
| `Data`  | Timeline parsing | The parsed observation fields and the audio they came from |
| `Stop`  | **Stop survey** | Final location and the GPS track as zipped GeoJSON |

All records are read-only once saved; the home screen opens them in the inspector.

## Hardware and permissions

Any phone or tablet. The screen is only a reminder of what can be said. A headset microphone makes a large difference in noisy environments. The form needs microphone permission and location permission set to *allow all the time* so tracking continues with the screen off.

## Build

```bash
formkit build talk-survey
```

Upload `build/talk-survey/form.xlsx` and `icon.png` to the backend. CyberTracker downloads the spreadsheet that KoBoToolbox regenerates from its import, not the file you uploaded, so a column KoBoToolbox renames or drops is lost on the device.
