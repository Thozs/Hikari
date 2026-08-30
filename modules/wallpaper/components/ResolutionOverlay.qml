import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../config" as ConfigModule
import "ResolutionPresets.js" as Presets
import "../../../services"

Item {
    id: overlay

    readonly property var c: ConfigModule.Theme
    readonly property string fontDisplay: "Noto Serif"
    readonly property string fontBody: "Noto Sans"

    property var wallpaper: null
    property bool open: false

    property int tab: 0 // 0 = PC, 1 = Celular
    property int selWidth: 0
    property int selHeight: 0
    property string selLabel: ""
    property int selFillMode: 1

    signal closed()

    anchors.fill: parent
    visible: open
    z: 999

    onOpenChanged: {
        if (open) {
            tab = 0
            selWidth = 0
            selHeight = 0
            selLabel = ""
            selFillMode = 1
            customWidthField.text = ""
            customHeightField.text = ""
            Monitors.refresh()
        }
    }

    function pickResolution(w, h, label) {
        selWidth = w
        selHeight = h
        selLabel = label
    }

    function isMonitorMatch(w, h) {
        for (var i = 0; i < Monitors.list.length; i++) {
            var m = Monitors.list[i]
            if (m.width === w && m.height === h)
                return true
        }
        return false
    }

    function confirm() {
        if (!wallpaper || selWidth <= 0 || selHeight <= 0)
            return
        if (tab === 0) {
            Wallpaper.downloadAndApply(wallpaper, selWidth, selHeight, selFillMode)
        } else {
            Wallpaper.downloadOnly(wallpaper, selWidth, selHeight, selFillMode, selLabel)
        }
        overlay.open = false
        overlay.closed()
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        MouseArea { anchors.fill: parent; onClicked: overlay.open = false }
    }

    Rectangle {
        id: dialog
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 560)
        height: Math.min(parent.height - 60, 520)
        radius: 16
        color: c.surface_container_low
        border.color: c.outline_variant
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Escolher resolução"
                    font.family: overlay.fontDisplay
                    font.pixelSize: 18
                    color: c.on_surface
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: closeArea.containsMouse ? c.surface_container_high : "transparent"
                    Text { anchors.centerIn: parent; text: "✕"; color: c.on_surface_variant; font.pixelSize: 12 }
                    MouseArea { id: closeArea; anchors.fill: parent; hoverEnabled: true; onClicked: overlay.open = false }
                }
            }

            Row {
                spacing: 8

                Rectangle {
                    width: pcLabel.implicitWidth + 24; height: 30; radius: 15
                    color: overlay.tab === 0 ? c.primary : c.surface_container
                    Text {
                        id: pcLabel
                        anchors.centerIn: parent
                        text: "PC"
                        font.family: overlay.fontBody
                        font.pixelSize: 12
                        font.bold: true
                        color: overlay.tab === 0 ? c.on_primary : c.on_surface_variant
                    }
                    MouseArea { anchors.fill: parent; onClicked: overlay.tab = 0 }
                }

                Rectangle {
                    width: mobileLabel.implicitWidth + 24; height: 30; radius: 15
                    color: overlay.tab === 1 ? c.primary : c.surface_container
                    Text {
                        id: mobileLabel
                        anchors.centerIn: parent
                        text: "Celular"
                        font.family: overlay.fontBody
                        font.pixelSize: 12
                        font.bold: true
                        color: overlay.tab === 1 ? c.on_primary : c.on_surface_variant
                    }
                    MouseArea { anchors.fill: parent; onClicked: overlay.tab = 1 }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "MODO DE PREENCHIMENTO"
                    font.family: overlay.fontBody
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                    color: c.on_surface_variant
                }

                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            { label: "Cortar", value: 1 },
                            { label: "Ajustar", value: 0 },
                            { label: "Esticar", value: 4 }
                        ]
                        delegate: Rectangle {
                            readonly property bool isSel: overlay.selFillMode === modelData.value
                            width: fmLabel.implicitWidth + 20
                            height: 28
                            radius: 8
                            color: isSel ? c.primary : c.surface_container
                            Text {
                                id: fmLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: overlay.fontBody
                                font.pixelSize: 11
                                color: isSel ? c.on_primary : c.on_surface
                            }
                            MouseArea { anchors.fill: parent; onClicked: overlay.selFillMode = modelData.value }
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: overlay.width > 0 ? dialog.width - 36 : 0
                    spacing: 14

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        visible: overlay.tab === 0

                        Repeater {
                            model: Presets.pcGroups
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: modelData.label
                                    font.family: overlay.fontBody
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.letterSpacing: 1
                                    color: c.on_surface_variant
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: modelData.items
                                        delegate: Rectangle {
                                            readonly property bool isSel: overlay.selWidth === modelData.width && overlay.selHeight === modelData.height
                                            readonly property bool isNative: overlay.isMonitorMatch(modelData.width, modelData.height)
                                            width: resLabel.implicitWidth + 20
                                            height: 30
                                            radius: 8
                                            color: isSel ? c.primary : c.surface_container
                                            border.width: isNative && !isSel ? 1.5 : 0
                                            border.color: c.primary

                                            Text {
                                                id: resLabel
                                                anchors.centerIn: parent
                                                text: modelData.width + "×" + modelData.height
                                                font.family: overlay.fontBody
                                                font.pixelSize: 11
                                                color: isSel ? c.on_primary : c.on_surface
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: overlay.pickResolution(modelData.width, modelData.height, modelData.width + "×" + modelData.height)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: Monitors.list.length > 0

                            Text {
                                text: "SEUS MONITORES"
                                font.family: overlay.fontBody
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1
                                color: c.on_surface_variant
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: Monitors.list
                                    delegate: Rectangle {
                                        readonly property bool isSel: overlay.selWidth === modelData.width && overlay.selHeight === modelData.height
                                        width: monLabel.implicitWidth + 20
                                        height: 30
                                        radius: 8
                                        color: isSel ? c.primary : c.surface_container_high

                                        Text {
                                            id: monLabel
                                            anchors.centerIn: parent
                                            text: modelData.name + " · " + modelData.width + "×" + modelData.height
                                            font.family: overlay.fontBody
                                            font.pixelSize: 11
                                            color: isSel ? c.on_primary : c.on_surface
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: overlay.pickResolution(modelData.width, modelData.height, modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: overlay.tab === 1

                        Text {
                            text: "PRESETS COMUNS"
                            font.family: overlay.fontBody
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1
                            color: c.on_surface_variant
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: Presets.mobilePresets
                                delegate: Rectangle {
                                    readonly property bool isSel: overlay.selWidth === modelData.width && overlay.selHeight === modelData.height
                                    width: mobResCol.implicitWidth + 20
                                    height: 42
                                    radius: 8
                                    color: isSel ? c.primary : c.surface_container

                                    ColumnLayout {
                                        id: mobResCol
                                        anchors.centerIn: parent
                                        spacing: 1
                                        Text {
                                            text: modelData.label
                                            font.family: overlay.fontBody
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: isSel ? c.on_primary : c.on_surface
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                        Text {
                                            text: modelData.width + "×" + modelData.height
                                            font.family: overlay.fontBody
                                            font.pixelSize: 9
                                            color: isSel ? c.on_primary : c.on_surface_variant
                                            Layout.alignment: Qt.AlignHCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: overlay.pickResolution(modelData.width, modelData.height, modelData.label)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text { text: "Custom:"; font.family: overlay.fontBody; font.pixelSize: 11; color: c.on_surface_variant }

                Rectangle {
                    width: 70; height: 28; radius: 6
                    color: c.surface_container
                    border.color: customWidthField.activeFocus ? c.primary : c.outline_variant
                    border.width: 1

                    TextInput {
                        id: customWidthField
                        anchors { fill: parent; margins: 6 }
                        color: c.on_surface
                        font.pixelSize: 11
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        validator: IntValidator { bottom: 1; top: 10000 }
                    }
                }

                Text { text: "×"; color: c.on_surface_variant; font.pixelSize: 12 }

                Rectangle {
                    width: 70; height: 28; radius: 6
                    color: c.surface_container
                    border.color: customHeightField.activeFocus ? c.primary : c.outline_variant
                    border.width: 1

                    TextInput {
                        id: customHeightField
                        anchors { fill: parent; margins: 6 }
                        color: c.on_surface
                        font.pixelSize: 11
                        horizontalAlignment: TextInput.AlignHCenter
                        verticalAlignment: TextInput.AlignVCenter
                        validator: IntValidator { bottom: 1; top: 10000 }
                    }
                }

                Rectangle {
                    width: 50; height: 28; radius: 6
                    color: c.surface_container_high
                    Text { anchors.centerIn: parent; text: "usar"; font.family: overlay.fontBody; font.pixelSize: 10; color: c.on_surface }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var w = parseInt(customWidthField.text)
                            var h = parseInt(customHeightField.text)
                            if (w > 0 && h > 0)
                                overlay.pickResolution(w, h, "Custom " + w + "×" + h)
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: overlay.selWidth > 0 ? ("Selecionado: " + overlay.selLabel + " (" + overlay.selWidth + "×" + overlay.selHeight + ")") : "Nenhuma resolução selecionada"
                    font.family: overlay.fontBody
                    font.pixelSize: 11
                    color: c.on_surface_variant
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 90; height: 32; radius: 16
                    color: c.surface_container
                    Text { anchors.centerIn: parent; text: "Cancelar"; font.family: overlay.fontBody; font.pixelSize: 11; color: c.on_surface }
                    MouseArea { anchors.fill: parent; onClicked: overlay.open = false }
                }

                Rectangle {
                    width: overlay.tab === 0 ? 130 : 90
                    height: 32; radius: 16
                    color: overlay.selWidth > 0 ? c.primary : c.surface_container
                    opacity: overlay.selWidth > 0 ? 1 : 0.5
                    Text {
                        anchors.centerIn: parent
                        text: overlay.tab === 0 ? "Baixar e Aplicar" : "Baixar"
                        font.family: overlay.fontBody
                        font.pixelSize: 11
                        font.bold: true
                        color: c.on_primary
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: overlay.selWidth > 0
                        onClicked: overlay.confirm()
                    }
                }
            }
        }
    }
}
