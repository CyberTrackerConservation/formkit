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

        property bool canEdit: form.getGlobal("canEdit", false)
        property bool editing: form.getGlobal("editing", false)

        property int columnCount: 0
        property int iconSize: 0
        property int padding: 0
    }

    PositionSource {
        id: positionSource
        active: true
        name: App.positionInfoSourceName
        updateInterval: 1000
    }

    SightingListModel {
        id: sightingListModel
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
            height: parent.height
            spacing: 0
            visible: internal.editing

            ToolButton {
                Layout.alignment: Qt.AlignVCenter
                icon.source: Style.cancelIconSource
                icon.width: Style.toolButtonSize
                icon.height: Style.toolButtonSize
                icon.color: h.textColor
                onClicked: {
                    root.cancelEdit()
                }
            }

            Label {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                Layout.fillWidth: true
                font.pixelSize: App.settings.font20
                horizontalAlignment: Qt.AlignHCenter
                clip: true
                color: h.textColor
                text: form.getFieldDisplayValue(form.rootRecordUid, "mission_id") + " (edit)"
            }

            ToolButton {
                Layout.alignment: Qt.AlignVCenter
                icon.source: Style.okIconSource
                icon.width: Style.toolButtonSize
                icon.height: Style.toolButtonSize
                icon.color: h.textColor
                onClicked: {
                    root.confirmEdit()
                }
            }
        }

        RowLayout {
            width: parent.width
            spacing: 0
            visible: !internal.editing

            RowLayout {
                Layout.preferredWidth: Style.toolButtonSize * 5
                Layout.maximumWidth: Style.toolButtonSize * 5
                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                spacing: 0

                ToolButton {
                    icon.source: Style.homeIconSource
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    onClicked: {
                        form.popPagesToParent()
                    }
                }

                ToolButton {
                    icon.source: App.locationLogger.stateIcon
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    onClicked: {
                        App.showToast(form.trackStreamer.rateFullText)
                    }
                }

                ToolButton {
                    icon.source: "qrc:/icons/map_outline.svg"
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    onClicked: {
                        form.pushPage("qrc:/MapsPage.qml")
                    }
                }

                ToolButton {
                    icon.source: App.batteryIcon
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    onClicked: {
                        App.showToast(App.batteryText)
                    }
                }

                ToolButton {
                    icon.source: "qrc:/icons/settings_outline.svg"
                    icon.width: Style.toolButtonSize
                    icon.height: Style.toolButtonSize
                    icon.color: h.textColor
                    enabled: bindCategory.value !== undefined
                    opacity: enabled ? 1.0 : 0.5
                    onClicked: {
                        setColumnCount(0)
                        setIconSize(0)
                        setPadding(0)

                        popupSettings.open()
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
                text: form.getFieldDisplayValue(form.rootRecordUid, "mission_id")
            }

            RowLayout {
                Layout.preferredWidth: Style.toolButtonSize * 5
                Layout.maximumWidth: Style.toolButtonSize * 5
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
                        let recordUid = form.rootRecordUid
                        let lastLocation = App.lastLocation.toMap

                        // Finalize the track.
                        form.pushTrackLocation(lastLocation)
                        form.snapTrack()
                        form.project.locationStreamingEnabled = false

                        // Create stop sighting.
                        form.setFieldValue(recordUid, "location", lastLocation)
                        form.setFieldValue(recordUid, "datetime", App.timeManager.currentDateTimeISO())
                        form.setFieldValue(recordUid, "type", "Stop")
                        form.resetFieldValue(recordUid, "observation_category")
                        form.resetFieldValue(recordUid, "observation_type")
                        form.resetFieldValue(recordUid, "measure_type")
                        form.resetFieldValue(recordUid, "measure")
                        form.resetFieldValue(recordUid, "in_out")
                        form.resetFieldValue(recordUid, "direction")
                        form.saveSighting()
                        form.markSightingCompleted()

                        // Reset.
                        form.newSighting()
                        form.wizard.init(form.rootRecordUid)
                        form.saveState()
                        form.loadPages()
                    }
                }
            }
        }
    }

    // Content.
    // Field bindings.
    FieldBinding {
        id: bindLocation
        recordUid: form.rootRecordUid
        fieldUid: "location"
    }

    FieldBinding {
        id: bindProtocol
        recordUid: form.rootRecordUid
        fieldUid: "protocol"
    }

    FieldBinding {
        id: bindCategory
        recordUid: form.rootRecordUid
        fieldUid: "observation_category"
    }

    FieldBinding {
        id: bindType
        recordUid: form.rootRecordUid
        fieldUid: "observation_type"
    }

    FieldBinding {
        id: bindMeasureType
        recordUid: form.rootRecordUid
        fieldUid: "measure_type"
    }

    FieldBinding {
        id: bindMeasure
        recordUid: form.rootRecordUid
        fieldUid: "measure"
    }

    FieldBinding {
        id: bindInOut
        recordUid: form.rootRecordUid
        fieldUid: "in_out"
    }

    FieldBinding {
        id: bindDirection
        recordUid: form.rootRecordUid
        fieldUid: "direction"
    }

    // Models.
    ElementListModel {
        id: modelCategory
        Component.onCompleted: {
            elementUid = bindCategory.field.listElementUid
        }
    }

    ElementListModel {
        id: modelType
        Component.onCompleted: {
            elementUid = bindType.field.listElementUid
        }
    }

    ElementListModel {
        id: modelMeasureType
        Component.onCompleted: {
            elementUid = bindMeasureType.field.listElementUid
        }
    }

    ElementListModel {
        id: modelInOut
        Component.onCompleted: {
            elementUid = bindInOut.field.listElementUid
        }
    }

    ElementListModel {
        id: modelDirection
        Component.onCompleted: {
            elementUid = bindDirection.field.listElementUid
        }
    }

    Item { height: App.scaleByFontSize(2) }

    Label {
        id: labelTitle
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        font.pixelSize: App.settings.font20
        font.bold: true
        text: getTitle()
    }

    Item { height: App.scaleByFontSize(2) }

    Rectangle {
        width: parent.width
        height: Style.lineWidth1
        color: Style.colorGroove
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        FieldGridView {
            id: gridCategory
            Layout.fillHeight: true
            Layout.preferredWidth: App.scaleByFontSize(52)
            opacity: 0.5
            topMargin: -Style.lineWidth1
            recordUid: form.rootRecordUid
            fieldUid: "observation_category"
            params: ({ columns: 1, lines: true, style: "IconOnly", itemHeight: App.scaleByFontSize(52) })
            onItemClicked: (elementUid) => {
                bindCategory.setValue(elementUid)
                let listElementUid = gridType.model.elementUid
                gridType.model.elementUid = ""
                gridType.model.elementUid = listElementUid
                updateTitle()

                internal.columnCount = getColumnCount()
                internal.iconSize = getIconSize()
                internal.padding = getPadding()

                gridType.params = makeParams()
            }
        }

        FieldGridView {
            id: gridType
            Layout.fillWidth: true
            Layout.fillHeight: true
            recordUid: form.rootRecordUid
            fieldUid: "observation_type"
            params: makeParams()

            onItemClicked: (elementUid) => {
                // Do not set the location for edited sightings.
                // Snap timestamp and location.
                if (!internal.editing) {
                    form.setFieldValue(form.rootRecordUid, "datetime", App.timeManager.currentDateTimeISO())
                    bindLocation.setValue(App.lastLocation.toMap)
                }

                bindType.setValue(elementUid)
                updateTitle()
            }
        }

        ColumnLayout {
            Layout.maximumWidth: App.scaleByFontSize(52) * 3
            Layout.fillHeight: true
            spacing: 0

            Row {
                Layout.fillWidth: true
                spacing: 0

                ButtonGroup {
                    id: buttonGroupMeasureType
                }

                Rectangle {
                    visible: bindProtocol.value === "protocol/recce"
                    width: parent.width
                    height: editButton.height
                    Material.background: "transparent"
                    Material.roundedScale: Material.NotRounded
                    enabled: false
                    color: "transparent"

                    Text {
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: form.getElementName("measure_type/count")
                        font.pixelSize: App.settings.font14
                    }
                }

                Repeater {
                    id: measureType
                    model: modelMeasureType
                    visible: bindProtocol.value !== "protocol/recce"

                    Button {
                        width: parent.width / modelMeasureType.count
                        ButtonGroup.group: buttonGroupMeasureType
                        Material.background: checked ? Material.accent : "transparent"
                        Material.roundedScale: Material.NotRounded

                        contentItem: Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: form.getElementName(modelData.uid)
                            color: parent.checked ? "white" : "black"
                            font.pixelSize: App.settings.font14
                            font.bold: parent.checked
                        }
                        checked: bindMeasureType.value === modelData.uid
                        onClicked: {
                            bindMeasureType.setValue(modelData.uid)
                        }
                    }
                }
            }

            FieldKeypad {
                id: keypad
                Layout.fillWidth: true
                height: App.scaleByFontSize(52) * 4
                recordUid: form.rootRecordUid
                fieldUid: "measure"
            }

            Row {
                Layout.fillWidth: true
                spacing: 0
                visible: bindProtocol.value === "protocol/sample"

                ButtonGroup {
                    id: buttonGroupInOut
                }

                Repeater {
                    model: modelInOut

                    Button {
                        width: parent.width / modelInOut.count
                        ButtonGroup.group: buttonGroupInOut
                        Material.background: checked ? Material.accent : "transparent"
                        Material.roundedScale: Material.NotRounded
                        checkable: true
                        contentItem: Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: form.getElementName(modelData.uid)
                            color: parent.checked ? "white" : "black"
                            font.pixelSize: App.settings.font14
                            font.bold: parent.checked
                        }
                        checked: bindInOut.value === modelData.uid
                        onClicked: {
                            bindInOut.setValue(modelData.uid)
                        }
                    }
                }
            }

            Row {
                Layout.fillWidth: true

                ButtonGroup {
                    id: buttonGroupDirection
                }

                Repeater {
                    model: modelDirection

                    Button {
                        width: parent.width / modelDirection.count
                        ButtonGroup.group: buttonGroupDirection
                        Material.background: checked ? Material.accent : "transparent"
                        Material.roundedScale: Material.NotRounded
                        checkable: true
                        contentItem: Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: form.getElementName(modelData.uid)
                            color: parent.checked ? "white" : "black"
                            font.pixelSize: App.settings.font14
                            font.bold: parent.checked
                        }
                        checked: bindDirection.value === modelData.uid
                        onClicked: {
                            bindDirection.setValue(modelData.uid)

                            if (!internal.editing) {
                                root.saveSighting()
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true

                Repeater {
                    model: [ { color: "#d62525", text: "Active" }, { color: "#e29b29", text: "Recent" }, { color: "#61ce63", text: "Old" } ]

                    Row {
                        Layout.fillWidth: true
                        spacing: App.scaleByFontSize(4)

                        Rectangle {
                            color: modelData.color
                            width: App.scaleByFontSize(16)
                            height: App.scaleByFontSize(16)
                        }

                        Label {
                            height: App.scaleByFontSize(16)
                            Layout.alignment: Qt.AlignVCenter
                            font.pixelSize: App.settings.font10
                            verticalAlignment: Label.AlignVCenter
                            text: modelData.text
                        }                        
                    }
                }
            }

            Item {
                height: App.scaleByFontSize(4)
            }

            Button {
                id: editButton
                Layout.fillWidth: true
                Material.roundedScale: Material.NotRounded
                Material.background: Material.Red
                visible: internal.canEdit && !internal.editing
                contentItem: Text {
                    width: parent.width
                    horizontalAlignment: Qt.AlignHCenter
                    font.pixelSize: App.settings.font14
                    text: "Edit last"
                    color: "white"
                }

                onClicked: {
                    root.startEdit()
                }
            }
        }
    }

    PopupBase {
        id: popupSettings

        contentItem: ColumnLayout {
            spacing: 0

            Component.onCompleted: {
                setProjectColors(popupSettings)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    text: "Columns"
                    font.pixelSize: App.settings.font14
                    clip: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.minimumWidth: App.scaleByFontSize(32)
                }

                Label {
                    font.pixelSize: App.settings.font14
                    opacity: 0.5
                    text: String(internal.columnCount)
                }

                ToolButton {
                    icon.source: "qrc:/icons/minus.svg"
                    icon.width: Style.toolButtonSize / 2
                    icon.height: Style.toolButtonSize / 2
                    opacity: 0.5
                    onClicked: {
                        setColumnCount(-1)
                    }
                }

                ToolButton {
                    icon.source: "qrc:/icons/plus.svg"
                    icon.width: Style.toolButtonSize / 2
                    icon.height: Style.toolButtonSize / 2
                    opacity: 0.5
                    onClicked: {
                        setColumnCount(1)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    text: "Icon size"
                    font.pixelSize: App.settings.font14
                    clip: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.minimumWidth: App.scaleByFontSize(32)
                }

                Label {
                    font.pixelSize: App.settings.font14
                    opacity: 0.5
                    text: String(internal.iconSize)
                }

                ToolButton {
                    icon.source: "qrc:/icons/minus.svg"
                    icon.width: Style.toolButtonSize / 2
                    icon.height: Style.toolButtonSize / 2
                    opacity: 0.5
                    onClicked: {
                        setIconSize(-1)
                    }
                }

                ToolButton {
                    icon.source: "qrc:/icons/plus.svg"
                    icon.width: Style.toolButtonSize / 2
                    icon.height: Style.toolButtonSize / 2
                    opacity: 0.5
                    onClicked: {
                        setIconSize(1)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Label {
                    text: "Padding"
                    font.pixelSize: App.settings.font14
                    clip: true
                }

                Item {
                    Layout.fillWidth: true
                    Layout.minimumWidth: App.scaleByFontSize(32)
                }

                Label {
                    font.pixelSize: App.settings.font14
                    opacity: 0.5
                    text: String(internal.padding)
                }

                ToolButton {
                    icon.source: "qrc:/icons/minus.svg"
                    icon.width: Style.toolButtonSize / 2
                    icon.height: Style.toolButtonSize / 2
                    opacity: 0.5
                    onClicked: {
                        setPadding(-1)
                    }
                }

                ToolButton {
                    icon.source: "qrc:/icons/plus.svg"
                    icon.width: Style.toolButtonSize / 2
                    icon.height: Style.toolButtonSize / 2
                    opacity: 0.5
                    onClicked: {
                        setPadding(1)
                    }
                }
            }
        }
    }

    function getTitle() {
        let elementUid = bindType.value
        if (elementUid === undefined) {
            elementUid = bindCategory.value
        }

        return elementUid === undefined ? "Select category" : form.getElementName(elementUid)
    }

    function updateTitle() {
        labelTitle.text = getTitle()
    }

    function getColumnCount() {
        return form.getGlobal("columns_" + bindCategory.value, internal.columnCount === 0 ? 8 : internal.columnCount)
    }

    function setColumnCount(delta) {
        let columns = getColumnCount() + delta

        if (columns < 3) {
            columns = 3
        } else if (columns > 12) {
            columns = 12
        }

        form.setGlobal("columns_" + bindCategory.value, columns)
        internal.columnCount = columns

        gridType.params = makeParams()
    }

    function getIconSize() {
        return form.getGlobal("itemHeight_" + bindCategory.value, internal.iconSize === 0 ? 64 : internal.iconSize)
    }

    function setIconSize(delta) {
        let itemHeight = getIconSize() + delta

        if (itemHeight < 32) {
            itemHeight = 32
        } else if (itemHeight > 256) {
            itemHeight = 256
        }

        form.setGlobal("itemHeight_" + bindCategory.value, itemHeight)
        internal.iconSize = itemHeight

        gridType.params = makeParams()
    }

    function getPadding() {
        return form.getGlobal("padding_" + bindCategory.value, internal.padding === 0 ? 4 : internal.padding)
    }

    function setPadding(delta) {
        let padding = getPadding() + delta

        if (padding < 0) {
            padding = 0
        } else if (padding > 256) {
            padding = 256
        }

        form.setGlobal("padding_" + bindCategory.value, padding)
        internal.padding = padding

        gridType.params = makeParams()
    }

    function makeParams() {
        let result = root.params
        result.columns = getColumnCount()
        result.itemHeight = getIconSize()
        result.padding = getPadding()

        return result
    }

    function newSighting() {
        let fieldUids = ["location", "observation_type", "measure_type", "measure", "in_out", "direction"]
        for (let i = 0; i < fieldUids.length; i++) {
            form.resetFieldValue(form.rootRecordUid, fieldUids[i])
        }

        form.newSighting(true)
        form.setGlobal("editing", false)

        form.loadPages()
        form.saveState()
    }

    function saveSighting() {
        // Recce type must be a count.
        if (bindProtocol.value === "protocol/recce") {
            bindMeasureType.setValue("measure_type/count")
        }

        // Ensure record is valid.
        let errorMessage = ""
        if (!form.getRecordValid(form.rootRecordUid)) {
            errorMessage = "Not complete"
        } else if (bindCategory.isEmpty) {
            errorMessage = "No category"
        } else if (bindType.isEmpty) {
            errorMessage = "No item selected"
        } else if (bindMeasureType.isEmpty) {
            errorMessage = "No measure type"
        } else if (bindMeasure.isEmpty) {
            errorMessage = "No measure"
        } else if (bindInOut.isEmpty && bindProtocol.value === "protocol/sample") {
            errorMessage = "No in/out specified"
        } else if (bindDirection.isEmpty) {
            errorMessage = "No direction specified"
        }

        if (errorMessage !== "") {
            bindDirection.resetValue()
            App.showError(errorMessage)
            return
        }

        // Save sighting.
        form.setFieldValue(form.rootRecordUid, "type", "")
        form.saveSighting()
        form.markSightingCompleted()

        // Specify that editing is now allowed.
        form.setGlobal("canEdit", true)

        // New sighting.
        newSighting()
    }

    function startEdit() {
        if (!form.getGlobal("canEdit", false)) {
            App.showError("No editable data")
            return
        }

        let sightingUid = sightingListModel.get(sightingListModel.count - 1).sightingUid
        form.setGlobal("editing", true)

        form.loadSighting(sightingUid)
        form.loadPages()

        form.saveState()
    }

    function cancelEdit() {
        newSighting()
    }

    function confirmEdit() {
        form.saveSighting()
        form.setGlobal("editing", false)
        newSighting()
    }
}
