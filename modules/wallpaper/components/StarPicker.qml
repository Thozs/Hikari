import QtQuick
import QtQuick.Layouts
import "../../../config" as ConfigModule
import "../../../services"

Item {
    id: picker

    readonly property var c: ConfigModule.Theme
    readonly property string fontBody: "Noto Sans"

    property bool open: false
    property string kind: ""     // "local" ou "wallhaven"
    property var payload: null   // local: {name, path} | wallhaven: objeto do Wallhaven
    property var checkedMap: ({})
    property var namesList: []
    property string newGroupText: ""

    signal confirmed(var selectedNames)

    anchors.fill: parent
    visible: open
    z: 998

    function openFor(k, p) {
        picker.kind = k
        picker.payload = p
        picker.newGroupText = ""
        picker._refresh()
        picker.open = true
    }

    function _refresh() {
        const names = Groups.groupNames()
        const current = picker.kind === "local" ? Groups.groupsForFile(picker.payload.name) : []
        const map = {}
        for (const n of names) map[n] = current.indexOf(n) !== -1
        picker.namesList = names
        picker.checkedMap = map
    }

    function toggleChecked(name) {
        const m = Object.assign({}, picker.checkedMap)
        m[name] = !m[name]
        picker.checkedMap = m
    }

    function createInline() {
        const name = picker.newGroupText.trim()
        if (name.length === 0) return
        if (Groups.createGroup(name)) {
            picker.newGroupText = ""
            picker._refresh()
            picker.toggleChecked(name)
        }
    }

    function confirm() {
        const selected = Object.keys(picker.checkedMap).filter(function (k) { return picker.checkedMap[k] })
        picker.confirmed(selected)
        picker.open = false
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        MouseArea { anchors.fill: parent; onClicked: picker.open = false }
    }

    Rectangle {
        id: dialog
        anchors.centerIn: parent
        width: Math.min(parent.width - 60, 340)
        height: Math.min(parent.height - 80, 420)
        radius: 16
        color: c.surfaceLow
        border.color: c.outlineVariant
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text {
                text: "Favoritar em quais grupos?"
                color: c.text
                font.family: picker.fontBody
                font.pixelSize: 14
                font.bold: true
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: picker.namesList
                spacing: 4

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 34
                    radius: 8
                    color: rowArea.containsMouse ? c.surface : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        Rectangle {
                            width: 18; height: 18; radius: 4
                            color: picker.checkedMap[modelData] ? c.accent : "transparent"
                            border.color: picker.checkedMap[modelData] ? c.accent : c.outlineVariant
                            border.width: 1.5
                            Text {
                                anchors.centerIn: parent
                                visible: picker.checkedMap[modelData]
                                text: "✓"
                                color: c.accentText
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            color: c.text
                            font.family: picker.fontBody
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: picker.toggleChecked(modelData)
                    }
                }
            }

            Text {
                visible: picker.namesList.length === 0
                text: "Nenhum grupo ainda — crie um abaixo."
                color: c.textMuted
                font.family: picker.fontBody
                font.pixelSize: 11
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: 8
                    color: c.surface
                    border.color: newGroupField.activeFocus ? c.accent : c.outlineVariant
                    border.width: 1

                    TextInput {
                        id: newGroupField
                        anchors { fill: parent; margins: 8 }
                        color: c.text
                        font.family: picker.fontBody
                        font.pixelSize: 12
                        clip: true
                        text: picker.newGroupText
                        onTextChanged: picker.newGroupText = text
                        Keys.onReturnPressed: picker.createInline()
                    }

                    Text {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 8 }
                        text: "novo grupo…"
                        color: c.textMuted
                        font.family: picker.fontBody
                        font.pixelSize: 12
                        opacity: 0.6
                        visible: newGroupField.text.length === 0
                    }
                }

                Rectangle {
                    width: 32; height: 32; radius: 8
                    color: c.surfaceHigh
                    Text { anchors.centerIn: parent; text: "+"; color: c.text; font.pixelSize: 16 }
                    MouseArea { anchors.fill: parent; onClicked: picker.createInline() }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    color: c.surface
                    Text { anchors.centerIn: parent; text: "Cancelar"; color: c.text; font.family: picker.fontBody; font.pixelSize: 12 }
                    MouseArea { anchors.fill: parent; onClicked: picker.open = false }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 17
                    color: c.accent
                    Text { anchors.centerIn: parent; text: "Aplicar"; color: c.accentText; font.family: picker.fontBody; font.pixelSize: 12; font.bold: true }
                    MouseArea { anchors.fill: parent; onClicked: picker.confirm() }
                }
            }
        }
    }
}
