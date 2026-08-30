import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls
import QtGraphicalEffects
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

            Rectangle {
                id: pill
                anchors.fill: parent
                radius: panel.pillRadius
                color: Theme.barBackground

                // Sombra sutil para diferenciar do background branco
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 0
                    verticalOffset: 1
                    radius: 4
                    samples: 8
                    color: Qt.rgba(0, 0, 0, 0.15)
                }

                // Grupo do topo: icone do launcher colado nos workspaces
                Loader {
                    anchors {
                        top: root.vertical ? parent.top : undefined
                        left: root.vertical ? undefined : parent.left
                        horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        topMargin: root.vertical ? 14 : 0
                        leftMargin: root.vertical ? 0 : 14
                    }
                    sourceComponent: root.vertical ? topStackVertical : topStackHorizontal
                }

                Component {
                    id: topStackVertical
                    Column {
                        spacing: 8

                        // Launcher Button com fundo
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.round(panel.thickness * 0.6) + 8
                            height: Math.round(panel.thickness * 0.6) + 8
                            radius: Math.round((Math.round(panel.thickness * 0.6) + 8) / 2)
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            LauncherButton {
                                anchors.centerIn: parent
                                thickness: panel.thickness
                            }
                        }

                        // Workspaces com fundo
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.round(panel.thickness * 0.55) * 5 + 8 * 4 + 16
                            height: Math.round(panel.thickness * 0.55) + 16
                            radius: Math.round(panel.thickness * 0.55) / 2 + 8
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Workspaces {
                                anchors.centerIn: parent
                                vertical: true
                                cellSize: Math.round(panel.thickness * 0.55)
                            }
                        }
                    }
                }

                Component {
                    id: topStackHorizontal
                    Row {
                        spacing: 8

                        // Launcher Button com fundo
                        Rectangle {
                            width: Math.round(panel.thickness * 0.6) + 8
                            height: Math.round(panel.thickness * 0.6) + 8
                            radius: Math.round((Math.round(panel.thickness * 0.6) + 8) / 2)
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            LauncherButton {
                                anchors.centerIn: parent
                                thickness: panel.thickness
                            }
                        }

                        // Workspaces com fundo
                        Rectangle {
                            width: Math.round(panel.thickness * 0.55) * 5 + 8 * 4 + 16
                            height: Math.round(panel.thickness * 0.55) + 16
                            radius: Math.round(panel.thickness * 0.55) / 2 + 8
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Workspaces {
                                anchors.centerIn: parent
                                vertical: false
                                cellSize: Math.round(panel.thickness * 0.55)
                            }
                        }
                    }
                }

                // Grupo de baixo: audio + relogio
                Loader {
                    anchors {
                        right: root.vertical ? undefined : parent.right
                        bottom: root.vertical ? parent.bottom : undefined
                        horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        rightMargin: root.vertical ? 0 : 14
                        bottomMargin: root.vertical ? 14 : 0
                    }
                    sourceComponent: root.vertical ? stackVertical : stackHorizontal
                }

                Component {
                    id: stackVertical
                    Column {
                        spacing: 8

                        // AudioIndicator com fundo
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.round(panel.thickness * 0.6) + 8
                            height: Math.round(panel.thickness * 0.6) + 8
                            radius: Math.round((Math.round(panel.thickness * 0.6) + 8) / 2)
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            AudioIndicator {
                                anchors.centerIn: parent
                                thickness: panel.thickness
                                vertical: true
                                screenRef: panel.screen
                                barPosition: Settings.barPosition
                                barMargin: Settings.barMargin
                                edgeInset: panel.lengthInset
                            }
                        }

                        // Relógio com fundo
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.round(panel.thickness * 0.40) * 2 + 20
                            height: Math.round(panel.thickness * 0.34) * 2 + 2 + 16
                            radius: Math.round(panel.thickness * 0.34) + 8
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
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

                Component {
                    id: stackHorizontal
                    Row {
                        spacing: 8

                        // AudioIndicator com fundo
                        Rectangle {
                            width: Math.round(panel.thickness * 0.6) + 8
                            height: Math.round(panel.thickness * 0.6) + 8
                            radius: Math.round((Math.round(panel.thickness * 0.6) + 8) / 2)
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            AudioIndicator {
                                anchors.centerIn: parent
                                thickness: panel.thickness
                                vertical: false
                                screenRef: panel.screen
                                barPosition: Settings.barPosition
                                barMargin: Settings.barMargin
                                edgeInset: panel.lengthInset
                            }
                        }

                        // Relógio com fundo
                        Rectangle {
                            width: Math.round(panel.thickness * 0.40) * 2 + 20
                            height: Math.round(panel.thickness * 0.40) + 16
                            radius: Math.round(panel.thickness * 0.40) / 2 + 8
                            color: Theme.moduleBackground
                            border.color: Theme.moduleBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
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
