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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PageHeader {
            id: h
            Layout.fillWidth: true
            text: "New survey"
            formBack: false
            backIcon: Style.homeIconSource
            backVisible: true
            onBackClicked: {
                form.wizard.home()
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
                recordUid: root.recordUid
                filterFieldUids: form.buildTaggedFields(root.recordUid, "timeline", "metadata")
            }

            delegate: FieldEditorDelegate {
                recordUid: root.recordUid
                fieldUid: model.fieldUid
                highlightInvalid: listView.highlightInvalid
                HorizontalDivider {}
            }
        }

        RowLayout {
            id: f
            Layout.fillWidth: true

            spacing: 0

            FooterButton {
                Layout.fillWidth: true
                text: qsTr("Back")
                icon.source: "qrc:/icons/arrow_back.svg"
                onClicked: form.wizard.back()
            }

            FooterButton {
                Layout.fillWidth: true
                text: qsTr("Start survey")
                icon.source: "qrc:/icons/play.svg"
                onClicked: {
                    // Validate the data.
                    for (let i = 0; i < fieldListModel.count; i++) {
                        if (!form.getFieldValueValid(root.recordUid, fieldListModel.get(i).fieldUid)) {
                            listView.highlightInvalid = true
                            return
                        }
                    }

                    // Start the track.
                    form.project.locationStreamingEnabled = true
                    form.pushTrackLocation(form.getFieldValue(root.recordUid, "location"))

                    // Save start sighting.
                    form.snapCreateTime()
                    form.setFieldValue(root.recordUid, "type", "Start")
                    form.saveSighting()
                    form.markSightingCompleted()

                    // New sighting.
                    form.newSighting(true)
                    form.wizard.skip(form.buildTaggedFields(form.rootRecordUid, "timeline", "fill")[0])
                }
            }
        }
    }
}
