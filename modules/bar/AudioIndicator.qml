import QtQuick
import QtQuick.Controls.Basic as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../../config"
import "../../services"

Item {
    id: root

    required property int thickness
    required property bool vertical
    required property var screenRef
    required property string barPosition
    required property int barMargin
    required property int edgeInset

    property int gap: 2
    property bool hovered: false
    property bool sinksExpanded: false
    property bool sourcesExpanded: false

    Timer {
        id: hideTimer
        interval: 250
        onTriggered: root.hovered = false
    }

    implicitWidth: root.vertical ? root.thickness * 0.6 : icon.implicitWidth + 4
    implicitHeight: root.vertical ? icon.implicitHeight + 4 : root.thickness * 0.6

    Text {
        id: icon
        anchors.centerIn: parent
        text: Audio.muted ? "🔇" : "🔊"
        color: Theme.text
        font.pixelSize: Math.round(root.thickness * 0.30)
    }

    HoverHandler {
        id: iconHover
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop();
                root.hovered = true;
            } else {
                hideTimer.restart();
            }
        }
    }

    TapHandler {
        onTapped: Audio.toggleMute()
    }

    PanelWindow {
        id: popout
        screen: root.screenRef
        color: "transparent"
        exclusiveZone: 0
        visible: root.hovered

        implicitWidth: 260
        implicitHeight: layout.implicitHeight + 24

        anchors {
            left: root.barPosition === "left"
            right: root.barPosition === "right"
            top: root.barPosition === "top"
            bottom: root.barPosition === "bottom" || root.barPosition === "left" || root.barPosition === "right"
        }

        margins {
            left: root.barPosition === "left" ? root.gap : 0
            right: root.barPosition === "right" ? root.gap : 0
            top: root.barPosition === "top" ? root.gap : 0
            bottom: (root.barPosition === "left" || root.barPosition === "right") ? root.edgeInset : (root.barPosition === "bottom" ? root.gap : 0)
        }

        Rectangle {
            id: content
            anchors.fill: parent
            radius: 12
            color: Theme.background
        }

        HoverHandler {
            id: popoutHover
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    root.hovered = true;
                } else {
                    hideTimer.restart();
                }
            }
        }

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Saída"
                    color: Theme.text
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Audio.muted ? "Mudo" : Math.round(Audio.volume * 100) + "%"
                    color: Theme.text
                    font.pixelSize: 13
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 6
                color: Qt.lighter(Theme.background, 1.4)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: Audio.sink?.description || Audio.sink?.name || "Nenhum"
                        color: Theme.text
                        font.pixelSize: 12
                    }

                    Text {
                        text: root.sinksExpanded ? "▲" : "▼"
                        color: Theme.text
                        font.pixelSize: 10
                    }
                }

                TapHandler {
                    onTapped: root.sinksExpanded = !root.sinksExpanded
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                visible: root.sinksExpanded
                spacing: 4

                Repeater {
                    model: Audio.sinks
                    delegate: Rectangle {
                        id: sinkRow
                        required property var modelData
                        visible: modelData.id !== Audio.sink?.id
                        Layout.fillWidth: true
                        implicitHeight: visible ? 26 : 0
                        color: "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            elide: Text.ElideRight
                            text: sinkRow.modelData.description || sinkRow.modelData.name
                            color: Theme.text
                            font.pixelSize: 12
                            opacity: 0.75
                            visible: sinkRow.visible
                        }

                        TapHandler {
                            onTapped: {
                                Audio.setAudioSink(sinkRow.modelData);
                                root.sinksExpanded = false;
                            }
                        }
                    }
                }
            }

            Controls.Slider {
                id: volumeSlider
                Layout.fillWidth: true
                from: 0
                to: Audio.maxVolume
                value: Audio.volume
                onMoved: Audio.setVolume(value)
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Text {
                    text: "Entrada (microfone)"
                    color: Theme.text
                    font.pixelSize: 13
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Audio.sourceMuted ? "Mudo" : Math.round(Audio.sourceVolume * 100) + "%"
                    color: Theme.text
                    font.pixelSize: 13
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 6
                color: Qt.lighter(Theme.background, 1.4)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: Audio.source?.description || Audio.source?.name || "Nenhum"
                        color: Theme.text
                        font.pixelSize: 12
                    }

                    Text {
                        text: root.sourcesExpanded ? "▲" : "▼"
                        color: Theme.text
                        font.pixelSize: 10
                    }
                }

                TapHandler {
                    onTapped: root.sourcesExpanded = !root.sourcesExpanded
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                visible: root.sourcesExpanded
                spacing: 4

                Repeater {
                    model: Audio.sources
                    delegate: Rectangle {
                        id: sourceRow
                        required property var modelData
                        visible: modelData.id !== Audio.source?.id
                        Layout.fillWidth: true
                        implicitHeight: visible ? 26 : 0
                        color: "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            elide: Text.ElideRight
                            text: sourceRow.modelData.description || sourceRow.modelData.name
                            color: Theme.text
                            font.pixelSize: 12
                            opacity: 0.75
                            visible: sourceRow.visible
                        }

                        TapHandler {
                            onTapped: {
                                Audio.setAudioSource(sourceRow.modelData);
                                root.sourcesExpanded = false;
                            }
                        }
                    }
                }
            }

            Controls.Slider {
                id: micSlider
                Layout.fillWidth: true
                from: 0
                to: Audio.maxVolume
                value: Audio.sourceVolume
                onMoved: Audio.setSourceVolume(value)
            }
        }
    }
}
