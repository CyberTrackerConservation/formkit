import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material
import CyberTracker

Item {
    id: root

    property string recordUid
    property string fieldUid
    property var params

    //Watermark.
    SquareIcon {
        id: watermark
        anchors.horizontalCenter: parent.horizontalCenter
        y: h.height + (listView.height - watermark.height) / 2
        source: App.projectManager.getFileUrl(form.project.uid, "wcs.svg")
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
            showStatusIcon: false
            filter.projectUid: form.project.uid
            filter.stateSpace: "*"
            showNullGroup: false
            checkable: false
            active: true

            onClicked: function (sighting, index) {
                if (sighting.trackOnly) {
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
                enabled: listView.canSubmitData
                icon.source: "qrc:/icons/upload_multiple.svg"
                onClicked: {
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
                icon.source: "qrc:/icons/plus.svg"
                onClicked: {
                    form.newSessionId()
                    form.newSighting(true)
                    form.setFieldValue(form.rootRecordUid, "survey_id", form.sessionId)
                    form.resetFieldValue(form.rootRecordUid, "location")
                    form.wizard.skip("location")
                }
            }
        }
    }
}
