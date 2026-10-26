import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import QtPositioning
import CyberTracker

ColumnLayout {
    id: root

    property string recordUid
    property string fieldUid
    property var params

    QtObject {
        id: internal

        property alias listening: recorder.listening
        property alias recording: recorder.recording
        property int duration: 0

        property string headerText: ""
        property var fillFieldUids: form.buildTaggedFields(form.rootRecordUid, "timeline", "fill")

        Component.onCompleted: {
            let metadataFields = form.buildTaggedFields(form.rootRecordUid, "timeline", "metadata")
            let headerFieldUid = metadataFields[metadataFields.length - 1]
            headerText = form.getFieldDisplayValue(form.rootRecordUid, headerFieldUid)
        }

    }

    SightingListModel {
        id: sightingListModel
        projectUid: form.projectUid
        stateSpace: form.stateSpace
    }

    PositionSource {
        id: positionSource
        active: true
        name: App.positionInfoSourceName
        updateInterval: 1000
    }

    VoiceRecorder {
        id: recorder

        speed: 1

        onVoiceStarted: function(filePath) {
            console.log("Voice started: " + filePath)
            form.snapCreateTime()
            form.setFieldValue(form.rootRecordUid, "location", App.lastLocation.toMap)
        }

        onVoiceCompleted: function(filePath, duration, deleted) {
            console.log("Voice completed: " + duration + "ms, deleted: " + deleted)
            if (deleted === true) {
                return
            }

            saveSighting(filePath, duration)
        }

        onDurationChanged: function() {
            internal.duration = recorder.duration
        }

        Component.onCompleted: {
            recorder.start()
        }
    }

    spacing: 0

    // Header.
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
                    opacity: enabled ? 1.0 : 0.5
                    onClicked: {
                        form.popPagesToParent()
                    }
                }

                ToolButton {
                    icon.source: App.locationLogger.stateIcon
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    opacity: enabled ? 1.0 : 0.5
                    onClicked: {
                        App.showToast(form.trackStreamer.rateFullText)
                    }
                }

                ToolButton {
                    icon.source: "qrc:/icons/map_outline.svg"
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    opacity: enabled ? 1.0 : 0.5
                    onClicked: {
                        form.pushPage("qrc:/MapsPage.qml")
                    }
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
                text: internal.headerText
            }

            RowLayout {
                Layout.preferredWidth: Style.toolButtonSize * 4
                Layout.maximumWidth: Style.toolButtonSize * 4
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                spacing: 0

                RoundButton {
                    id: stopButton
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    text: "Stop survey"
                    font.pixelSize: App.settings.font12
                    radius: App.scaleByFontSize(4)
                    onClicked: {
                        stopSurvey()
                    }
                }
            }
        }
    }

    ListViewV {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        property bool highlightInvalid: false

        spacing: 0

        model: FieldListProxyModel {
            id: fieldListModel
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
                    wrapMode: Label.WordWrap
                    font.bold: true
                    text: {
                        let timelineParams = form.project.timelineParams
                        return "Say '" + timelineParams.commandStart + "', the fields below and then '" + timelineParams.commandStop + "'"
                    }
                }

                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Qt.AlignHCenter
                    font.pixelSize: App.settings.font14
                    wrapMode: Label.WordWrap
                    font.bold: true
                    text: {
                        let timelineParams = form.project.timelineParams
                        return "Say '" + timelineParams.commandError + "', the fields below end then '" + timelineParams.commandStop + "' to correct the prior observation"
                    }
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
                    spacing: App.scaleByFontSize(5) // default value for ColumnLayout
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
                        text: {
                            let field = form.getField(model.fieldUid)
                            let fieldType = form.getFieldType(model.fieldUid)
                            let listElementUid = form.getField(model.fieldUid).listElementUid
                            switch (fieldType) {
                            case "NumberField":
                                return createNumberString(field.minValue, field.maxValue, field.decimals)

                            case "CheckField":
                                return listElementUid !== "" ? getListItems(listElementUid) : "Yes or no"

                            case "StringField":
                                return listElementUid !== "" ? getListItems(listElementUid) : "Text..."
                            }

                            return "";
                        }
                        wrapMode: Label.Wrap
                        visible: text !== ""
                        font.pixelSize: App.settings.font14
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

    HorizontalDivider { Layout.fillWidth: true; height: App.scaleByFontSize(2) }

    Pane {
        Layout.fillWidth: true
        contentItem: RowLayout {
            width: parent.width

            SquareIcon {
                id: blinker

                source: {
                    if (internal.recording) {
                        return "qrc:/icons/account_voice.svg"
                    } else {
                        return "qrc:/icons/microphone.svg"
                    }
                }

                color: {
                    if (internal.recording) {
                        return "red"
                    } else if (internal.listening) {
                        return "blue"
                    } else {
                        return "#808080"
                    }
                }

                Timer {
                    id: blinkTimer
                    running: true
                    repeat: true
                    interval: 1000
                    onTriggered: {
                       blinker.opacity = blinker.opacity === 0.0 ? 1.0 : 0.0
                    }
                }
            }

            Label {
                font.pixelSize: App.settings.font14
                font.family: "monospace"
                horizontalAlignment: Qt.AlignHCenter
                text: recorder.stateText + (recorder.recording ? " \u00B7 " + recorder.durationText : "")
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                font.pixelSize: App.settings.font14
                font.family: "monospace"
                horizontalAlignment: Qt.AlignHCenter
                text: "Recordings" + " \u00B7 " + sightingListModel.count
            }
        }
    }

    // Content.

    function newSighting() {
        form.newSighting(true)
        form.resetFieldValue(form.rootRecordUid, "type")
        form.resetFieldValue(form.rootRecordUid, "audio")
        form.resetFieldValue(form.rootRecordUid, "location")
        form.saveState()
    }

    function saveSighting(audioFilePath, duration) {
        let recordUid = form.rootRecordUid

        form.setFieldValue(recordUid, "type", "Voice")

        let mediaFilename = App.moveToMedia(audioFilePath)
        form.setFieldValue(recordUid, "audio", ({ filename: mediaFilename, duration: duration, timestamp: form.sighting.createTime }))

        let timelineParams = form.project.timelineParams
        let speechPrompt = timelineParams.commandStart + " " +
                           timelineParams.commandStop + " " +
                           timelineParams.commandError + " " +
                           form.buildSpeechPrompt(form.rootRecordUid, internal.fillFieldUids)

        form.requestTranscribe(mediaFilename, speechPrompt);

        form.saveSighting()
        form.markSightingCompleted()

        // New sighting.
        newSighting()
    }

    function stopSurvey() {
        // Stop and save currently running audio.
        recorder.flush()

        // Create a survey sighting.
        let recordUid = form.rootRecordUid
        let location = App.lastLocation.toMap

        // Finalize the track.
        form.pushTrackLocation(location)
        form.snapTrack()
        form.project.locationStreamingEnabled = false

        // Create stop sighting.
        form.snapCreateTime()
        form.setFieldValue(recordUid, "location", location)
        form.setFieldValue(recordUid, "type", "Stop")
        form.saveSighting()
        form.markSightingCompleted()

        // Pend this session for timeline.
        form.appendPendingSessionId(form.sessionId)

        // Reset.
        form.newSighting()
        form.wizard.init(form.rootRecordUid)
        form.saveState()
        form.loadPages()
    }

    function getListItems(elementUid) {
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

            let aliases = elements[i].aliases
            for (let j = 0; j < aliases.length; j++) {
                result += ' / ' + aliases[j]
            }
        }

        return result
    }

    function createNumberString(minValue, maxValue, decimals) {
        const hasMin = Number.isFinite(minValue);
        const hasMax = Number.isFinite(maxValue);

        const base = 123.456789;

        let value;

        if (hasMin && hasMax) {
            const low = Math.min(minValue, maxValue);
            const high = Math.max(minValue, maxValue);
            const range = high - low;

            value = range === 0 ? low : low + (base % range);

        } else if (hasMin) {
            value = minValue + base;

        } else if (hasMax) {
            value = maxValue >= base ? base : maxValue;

        } else {
            value = base;
        }

        // Handle decimals
        if (!Number.isFinite(decimals) || decimals < 0) {
            // "don't care" → return natural string
            return String(value);
        }

        const places = Math.min(100, Math.floor(decimals));
        return value.toFixed(places);
    }
}
