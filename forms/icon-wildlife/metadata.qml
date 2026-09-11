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
                filterFieldUids: [
                    "location",
                    "aircraft_registration",
                    "pilot",
                    "pilot_other",
                    "fso",
                    "fso_other",
                    "rso_l",
                    "rso_l_other",
                    "rso_r",
                    "rso_r_other",
                    "protocol",
                    "site"
                ]
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

                    // Set the mission_id.
                    {
                        const date = new Date()
                        const day = date.getDate().toString().padStart(2, '0')
                        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
                        const month = monthNames[date.getMonth()]
                        const year = date.getFullYear()

                        let site = form.getFieldValue(root.recordUid, "site", "")
                        const sitePrefix = site.length < 3 ? site : site.substring(0, 3)

                        let mission_id = `${day}${month}${year}${sitePrefix}`

                        form.setFieldValue(root.recordUid, "mission_id", mission_id)
                    }

                    // Start the track.
                    form.project.locationStreamingEnabled = true
                    form.pushTrackLocation(form.getFieldValue(root.recordUid, "location"))

                    // Save start sighting.
                    form.setFieldValue(root.recordUid, "datetime", App.timeManager.currentDateTimeISO())
                    form.setFieldValue(root.recordUid, "type", "Start")
                    form.saveSighting()
                    form.markSightingCompleted()

                    // New sighting.
                    form.newSighting(true)
                    form.setGlobal("collectRecordUid", form.rootRecordUid)
                    form.setGlobal("editing", false)
                    form.setGlobal("canEdit", false)
                    form.wizard.skip("observation_category")
                }
            }
        }
    }
}
