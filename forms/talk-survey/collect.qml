import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import CyberTracker

// Collection. Runs the voice recorder continuously; each utterance becomes a Voice record with its audio,
// location and time, queued for transcription. The screen is a reminder of what can be said. Stop survey snaps
// the track onto the Stop record and pends the session for the timeline on the home screen.
ColumnLayout {
    id: root

    property string recordUid
    property string fieldUid
    property var params

    QtObject {
        id: internal

        property alias listening: recorder.listening
        property alias recording: recorder.recording

        property string headerText: ""
        property var fillFieldUids: form.buildTaggedFields(form.rootRecordUid, "timeline", "fill")

        Component.onCompleted: {
            let metadataFields = form.buildTaggedFields(form.rootRecordUid, "timeline", "metadata")
            if (metadataFields.length > 0) {
                headerText = form.getFieldDisplayValue(form.rootRecordUid, metadataFields[metadataFields.length - 1])
            }
        }
    }

    // Deferred so it runs after the list has laid out and restored any saved position.
    Component.onCompleted: Qt.callLater(listView.positionViewAtBeginning)

    SightingListModel {
        id: sightingListModel
        projectUid: form.projectUid
        stateSpace: form.stateSpace
    }

    VoiceRecorder {
        id: recorder

        speed: 1

        onVoiceStarted: function (filePath) {
            form.snapCreateTime()
            form.setFieldValue(form.rootRecordUid, "location", App.lastLocation.toMap)
        }

        onVoiceCompleted: function (filePath, duration, deleted) {
            if (deleted === true) {
                return
            }

            saveClip(filePath, duration)
        }

        Component.onCompleted: {
            recorder.start()
        }
    }

    spacing: 0

    // Header: home, track state, map, the session title, and Stop survey.
    Rectangle {
        id: h
        Layout.fillWidth: true

        property string textColor: Utils.lightness(Material.primary) < 130 ? "white" : "black"
        color: Material.primary
        height: Math.max(toolbarInternal.implicitHeight, titleRow.implicitHeight) + App.scaleByFontSize(4)

        ToolBar {
            id: toolbarInternal
            visible: false
        }

        RowLayout {
            width: parent.width
            spacing: 0

            RowLayout {
                Layout.preferredWidth: Style.toolButtonSize * 4
                Layout.maximumWidth: Style.toolButtonSize * 4
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                spacing: 0

                ToolButton {
                    icon.source: Style.homeIconSource
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    // Leave the project with this screen on the saved stack: reopening returns here, mid-session.
                    onClicked: {
                        recorder.flush()
                        App.popPageStack()
                    }
                }

                ToolButton {
                    icon.source: App.locationLogger.stateIcon
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    onClicked: App.showToast(form.trackStreamer.rateFullText)
                }

                ToolButton {
                    icon.source: "qrc:/icons/map_outline.svg"
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    onClicked: form.pushPage("qrc:/MapsPage.qml")
                }
            }

            Label {
                id: titleRow
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.fillWidth: true
                font.pixelSize: App.settings.font20
                horizontalAlignment: Qt.AlignHCenter
                clip: true
                color: h.textColor
                text: internal.headerText !== "" ? internal.headerText : form.project.name
            }

            RowLayout {
                Layout.preferredWidth: Style.toolButtonSize * 4
                Layout.maximumWidth: Style.toolButtonSize * 4
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                spacing: 0

                RoundButton {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    text: qsTr("Stop survey")
                    font.pixelSize: App.settings.font12
                    radius: App.scaleByFontSize(4)
                    onClicked: stopSurvey()
                }
            }
        }
    }

    // The prompt sheet: every spoken field and the values it accepts.
    ListViewV {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        model: FieldListProxyModel {
            recordUid: form.rootRecordUid
            filterFieldUids: internal.fillFieldUids
        }

        header: ItemDelegate {
            width: parent.width
            contentItem: ColumnLayout {
                width: parent.width

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Qt.AlignHCenter
                    font.pixelSize: App.settings.font14
                    font.bold: true
                    wrapMode: Label.WordWrap
                    text: qsTr("Say '%1', the fields below, then '%2'").arg(form.project.timelineParams.commandStart).arg(form.project.timelineParams.commandStop)
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Qt.AlignHCenter
                    font.pixelSize: App.settings.font14
                    font.bold: true
                    wrapMode: Label.WordWrap
                    text: qsTr("Say '%1', the fields, then '%2' to correct the previous observation").arg(form.project.timelineParams.commandError).arg(form.project.timelineParams.commandStop)
                }
            }

            HorizontalDivider { height: App.scaleByFontSize(2) }
        }

        delegate: ItemDelegate {
            width: listView.width
            contentItem: RowLayout {
                Item { height: Style.minRowHeight }

                Column {
                    Layout.fillWidth: true
                    spacing: App.scaleByFontSize(5)
                    height: listTitle.implicitHeight + listValue.implicitHeight

                    FieldName {
                        id: listTitle
                        recordUid: form.rootRecordUid
                        fieldUid: model.fieldUid
                        width: parent.width
                        font.pixelSize: App.settings.font14
                        font.bold: true
                    }

                    Label {
                        id: listValue
                        width: parent.width
                        wrapMode: Label.Wrap
                        visible: text !== ""
                        font.pixelSize: App.settings.font14
                        text: acceptedValues(model.fieldUid)
                    }
                }

                SquareIcon {
                    source: form.getFieldIcon(model.fieldUid)
                    size: Style.minRowHeight
                    visible: source !== ""
                }
            }

            HorizontalDivider {}
        }
    }

    // Footer: recorder state and the clip count.
    HorizontalDivider { Layout.fillWidth: true; height: App.scaleByFontSize(2) }

    Pane {
        Layout.fillWidth: true
        contentItem: RowLayout {
            width: parent.width

            SquareIcon {
                id: blinker
                source: internal.recording ? "qrc:/icons/account_voice.svg" : "qrc:/icons/microphone.svg"
                color: internal.recording ? "red" : (internal.listening ? "blue" : "#808080")

                Timer {
                    running: true
                    repeat: true
                    interval: 1000
                    onTriggered: blinker.opacity = blinker.opacity === 0.0 ? 1.0 : 0.0
                }
            }

            Label {
                font.pixelSize: App.settings.font14
                font.family: "monospace"
                text: recorder.stateText + (recorder.recording ? " · " + recorder.durationText : "")
            }

            Item { Layout.fillWidth: true }

            Label {
                font.pixelSize: App.settings.font14
                font.family: "monospace"
                text: qsTr("Recordings") + " · " + sightingListModel.count
            }
        }
    }

    function acceptedValues(fieldUid) {
        let field = form.getField(fieldUid)
        let listElementUid = field.listElementUid
        switch (form.getFieldType(fieldUid)) {
        case "NumberField":
            return qsTr("A number")

        case "CheckField":
            return listElementUid !== "" ? listItems(listElementUid) : qsTr("Yes or no")

        case "StringField":
            return listElementUid !== "" ? listItems(listElementUid) : qsTr("Text")
        }

        return ""
    }

    function listItems(elementUid) {
        let elements = form.getElement(elementUid).elements
        let result = ""
        for (let i = 0; i < elements.length; i++) {
            if (elements[i].other) {
                continue
            }

            if (result !== "") {
                result += ", "
            }

            result += form.getElementName(elements[i].uid)
        }

        return result
    }

    // A clip record: type Voice, the audio, the location snapped when speech started, and a transcription
    // request whose transcript lands in the transcribe field.
    function saveClip(audioFilePath, duration) {
        let recordUid = form.rootRecordUid
        let mediaFilename = App.moveToMedia(audioFilePath)

        form.setFieldValue(recordUid, "type", "Voice")
        form.setFieldValue(recordUid, "audio", ({ filename: mediaFilename, duration: duration, timestamp: form.sighting.createTime }))

        let timelineParams = form.project.timelineParams
        let speechPrompt = timelineParams.commandStart + " " + timelineParams.commandStop + " " + timelineParams.commandError + " " +
                           form.buildSpeechPrompt(recordUid, internal.fillFieldUids)
        form.requestTranscribe(mediaFilename, speechPrompt)

        form.saveSighting()
        form.markSightingCompleted()
        form.markSightingReadonly()

        newClip()
    }

    // Next clip copies the session values; clear what belongs to the previous record.
    function newClip() {
        form.newSighting(true)
        form.resetFieldValue(form.rootRecordUid, "type")
        form.resetFieldValue(form.rootRecordUid, "audio")
        form.resetFieldValue(form.rootRecordUid, "transcribe")
        form.resetFieldValue(form.rootRecordUid, "location")
        form.saveState()
    }

    // The Stop record carries the session track.
    function stopSurvey() {
        recorder.flush()

        let recordUid = form.rootRecordUid
        let location = App.lastLocation.toMap

        form.pushTrackLocation(location)
        form.snapTrack()
        form.project.locationStreamingEnabled = false

        form.snapCreateTime()
        form.setFieldValue(recordUid, "location", location)
        form.setFieldValue(recordUid, "type", "Stop")
        form.saveSighting()
        form.markSightingCompleted()
        form.markSightingReadonly()

        // Pend this session for the timeline.
        form.appendPendingSessionId(form.sessionId)

        // Back to the home screen.
        form.newSighting()
        form.wizard.init(form.rootRecordUid)
        form.saveState()
        form.loadPages()
    }
}
