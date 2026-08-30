import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import "../../config"

Scope {
    id: root
    property string hours: "00"
    property string minutes: "00"
    property bool vertical: Settings.barPosition === "left" || Settings.barPosition === "right"

    Process {
        id: dateProc
        command: ["date", "+%H:%M"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split(":")
                root.hours = parts[0]
                root.minutes = parts[1]
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: dateProc.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            color: "transparent"

            readonly property int thickness: Math.round(Math.max(
                Settings.barThicknessMin,
                Math.min(Settings.barThicknessMax, screen.height * Settings.barThicknessRatio)
            ))
            readonly property int pillRadius: thickness / 2
            readonly property int lengthInset: Math.round(
                (root.vertical ? screen.height : screen.width) * Settings.barVerticalInsetRatio
            )

            implicitWidth: root.vertical ? thickness : 0
            implicitHeight: root.vertical ? 0 : thickness

            anchors {
                top: Settings.barPosition === "top" || root.vertical
                bottom: Settings.barPosition === "bottom" || root.vertical
                left: Settings.barPosition === "left" || !root.vertical
                right: Settings.barPosition === "right" || !root.vertical
            }

            margins {
                left: Settings.barPosition === "left" ? Settings.barMargin : (!root.vertical ? panel.lengthInset : 0)
                right: Settings.barPosition === "right" ? Settings.barMargin : (!root.vertical ? panel.lengthInset : 0)
                top: Settings.barPosition === "top" ? Settings.barMargin : (root.vertical ? panel.lengthInset : 0)
                bottom: Settings.barPosition === "bottom" ? Settings.barMargin : (root.vertical ? panel.lengthInset : 0)
            }

            // Sombra sutil (Rectangle atrás da pill)
            Rectangle {
                id: pillShadow
                anchors.fill: parent
                radius: panel.pillRadius
                color: Qt.rgba(0, 0, 0, root.vertical ? 0.1 : 0.12)
                visible: true
                z: -1
                // Offset leve para baixo/direita
                x: root.vertical ? 1 : 0
                y: root.vertical ? 0 : 1
            }

            Rectangle {
                id: pill
                anchors.fill: parent
                radius: panel.pillRadius
                color: Theme.barBackground

                // Grupo do topo: LauncherButton + Workspaces em uma única pílula de fundo
                Loader {
                    anchors {
                        top: root.vertical ? parent.top : undefined
                        left: root.vertical ? undefined : parent.left
                        horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        topMargin: root.vertical ? 10 : 0
                        leftMargin: root.vertical ? 0 : 10
                    }
                    sourceComponent: root.vertical ? topStackVertical : topStackHorizontal
                }

                Component {
                    id: topStackVertical
                    Column {
                        spacing: 6

                        // Fundo único em pílula para LauncherButton + Workspaces
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(
                                Math.round(panel.thickness * 0.6) + 16,
                                Math.round(panel.thickness * 0.55) * 5 + 8 * 4 + 24
                            )
                            height: (Math.round(panel.thickness * 0.6) + 16) + 6 + (Math.round(panel.thickness * 0.55) + 16)
                            radius: panel.pillRadius
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                LauncherButton {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    thickness: panel.thickness
                                }

                                Workspaces {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    vertical: true
                                    cellSize: Math.round(panel.thickness * 0.55)
                                }
                            }
                        }
                    }
                }

                Component {
                    id: topStackHorizontal
                    Row {
                        spacing: 6

                        // Fundo único em pílula para LauncherButton + Workspaces
                        Rectangle {
                            width: (Math.round(panel.thickness * 0.6) + 16) + 6 + (Math.round(panel.thickness * 0.55) * 5 + 8 * 4 + 24)
                            height: Math.max(
                                Math.round(panel.thickness * 0.6) + 16,
                                Math.round(panel.thickness * 0.55) + 16
                            )
                            radius: panel.pillRadius
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                LauncherButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    thickness: panel.thickness
                                }

                                Workspaces {
                                    anchors.verticalCenter: parent.verticalCenter
                                    vertical: false
                                    cellSize: Math.round(panel.thickness * 0.55)
                                }
                            }
                        }
                    }
                }

                // Grupo de baixo: AudioIndicator + Relógio em uma única pílula de fundo
                Loader {
                    anchors {
                        right: root.vertical ? undefined : parent.right
                        bottom: root.vertical ? parent.bottom : undefined
                        horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        rightMargin: root.vertical ? 0 : 10
                        bottomMargin: root.vertical ? 10 : 0
                    }
                    sourceComponent: root.vertical ? stackVertical : stackHorizontal
                }

                Component {
                    id: stackVertical
                    Column {
                        spacing: 6

                        // Fundo único em pílula para AudioIndicator + Relógio
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.max(
                                Math.round(panel.thickness * 0.6) + 16,
                                Math.round(panel.thickness * 0.40) * 2 + 20
                            )
                            height: (Math.round(panel.thickness * 0.6) + 16) + 6 + (Math.round(panel.thickness * 0.34) * 2 + 2 + 16)
                            radius: panel.pillRadius
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                AudioIndicator {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    thickness: panel.thickness
                                    vertical: true
                                    screenRef: panel.screen
                                    barPosition: Settings.barPosition
                                    barMargin: Settings.barMargin
                                    edgeInset: panel.lengthInset
                                }

                                Column {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.hours
                                        color: Theme.barText
                                        font.pixelSize: Math.round(panel.thickness * 0.34)
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: root.minutes
                                        color: Theme.barText
                                        font.pixelSize: Math.round(panel.thickness * 0.34)
                                    }
                                }
                            }
                        }
                    }
                }

                Component {
                    id: stackHorizontal
                    Row {
                        spacing: 6

                        // Fundo único em pílula para AudioIndicator + Relógio
                        Rectangle {
                            width: (Math.round(panel.thickness * 0.6) + 16) + 6 + (Math.round(panel.thickness * 0.40) * 2 + 20)
                            height: Math.max(
                                Math.round(panel.thickness * 0.6) + 16,
                                Math.round(panel.thickness * 0.40) + 16
                            )
                            radius: panel.pillRadius
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                AudioIndicator {
                                    anchors.verticalCenter: parent.verticalCenter
                                    thickness: panel.thickness
                                    vertical: false
                                    screenRef: panel.screen
                                    barPosition: Settings.barPosition
                                    barMargin: Settings.barMargin
                                    edgeInset: panel.lengthInset
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.hours + ":" + root.minutes
                                    color: Theme.barText
                                    font.pixelSize: Math.round(panel.thickness * 0.40)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
