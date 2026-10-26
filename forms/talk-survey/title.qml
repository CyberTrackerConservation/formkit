import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import CyberTracker

// Home screen. A survey is a session: the observer speaks, each clip is transcribed, and the timeline turns the
// session into one Data record per observation. Whether clips are kept or deleted afterwards is set by
// timeline.deleteSources and timeline.deleteEmpty in form.xlsx; this form keeps them all.
// Records are submitted when the user presses Submit, never on save.
Item {
    id: root

    property string recordUid
    property string fieldUid
    property var params

    QtObject {
        id: internal
        property bool working: false
    }

    // Watermark.
    SquareIcon {
        id: watermark
        anchors.horizontalCenter: parent.horizontalCenter
        y: h.height + (listView.height - watermark.height) / 2
        source: App.projectManager.getFileUrl(form.project.uid, form.project.icon)
        size: Math.min(parent.width, parent.height) / 2
        opacity: 0.15
        recolor: false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PageHeader {
            id: h
            Layout.fillWidth: true
            text: form.project.name
            formBack: false
            backIcon: Style.homeIconSource
            backVisible: true
            onBackClicked: {
                form.wizard.home()
            }
        }

        SightingsListView {
            id: listView

            Layout.fillWidth: true
            Layout.fillHeight: true

            showNoData: false
            showStatusIcon: true
            filter.projectUid: form.project.uid
            filter.stateSpace: "*"
            groupBy: 6 /*SightingListModel.GroupBy.SessionId*/
            showNullGroup: false
            checkable: false
            active: true

            // Nothing is edited here: the stop record carries the session track, so show it; every other record
            // is shown in the inspector.
            onClicked: function (sighting, index) {
                if (sighting.trackOnly) {
                    return
                }

                if (sighting.trackFileName !== "") {
                    showTrackFile(page, sighting.trackFileName, sighting.trackFileSummary)
                    return
                }

                appPageStack.pushPageImmediate("qrc:/InspectorPage.qml", { inspectList: listView.model, initialIndex: index })
            }
        }

        RowLayout {
            id: f

            Layout.fillWidth: true

            spacing: 0

            FooterButton {
                Layout.fillWidth: true
                text: qsTr("Submit")
                enabled: listView.canSubmitData && !internal.working
                icon.source: "qrc:/icons/upload_multiple.svg"
                onClicked: {
                    if (App.transcribeQueue.working) {
                        App.showError(qsTr("Wait, transcription in progress"))
                        return
                    }

                    popupSubmit.open()
                }

                PopupLoader {
                    id: popupSubmit
                    popupComponent: Component {
                        ConfirmPopup {
                            icon: "qrc:/icons/upload_multiple.svg"
                            text: qsTr("Submit data?")
                            confirmDelay: false
                            onConfirmed: {
                                form.submitData()
                            }
                        }
                    }
                }
            }

            FooterButton {
                Layout.fillWidth: true
                text: qsTr("Map")
                icon.source: "qrc:/icons/map_outline.svg"
                onClicked: form.pushPage("qrc:/MapsPage.qml")
            }

            FooterButton {
                Layout.fillWidth: true
                text: qsTr("New survey")
                enabled: !internal.working
                icon.source: "qrc:/icons/plus.svg"
                onClicked: {
                    form.newSessionId()
                    form.newSighting(true)

                    // Every record of the survey carries its session id; clips copy it from here.
                    form.setFieldValue(form.rootRecordUid, "survey_id", form.sessionId)
                    form.resetFieldValue(form.rootRecordUid, "location")
                    form.wizard.skip("location")
                }
            }
        }
    }

    // Turns each finished session's clips into observation sightings, then fills their fields from the text.
    // The command words and the deleteEmpty and deleteSources policies come from the bind::ct:timeline.*
    // settings in form.xlsx; only the field names are declared here.
    Timeline {
        id: timeline
        audioFieldUid: "audio"
        locationFieldUid: "location"
        transcribeFieldUid: "transcribe"
        sessionIdFieldUid: "survey_id"
        fillFieldUids: form.buildTaggedFields(form.rootRecordUid, "timeline", "fill")
        extraFieldValues: ({ type: "Data" })
    }

    Component.onCompleted: {
        // Sightings are deleted from the device once the server has them.
        form.deleteSightingsOnUpload = true

        processSessions()
    }

    Connections {
        target: App.transcribeQueue

        function onWorkingChanged() {
            internal.working = App.transcribeQueue.hasWork()
        }

        function onWorkCompleted() {
            processSessions()
        }
    }

    // Process sessions whose clips are all transcribed. Submission is manual, from the Submit button.
    function processSessions() {
        timeline.processPendingSessions()
        internal.working = App.transcribeQueue.hasWork()
    }
}
