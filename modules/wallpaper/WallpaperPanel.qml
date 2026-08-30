import Quickshell
import Quickshell.Io
import QtQuick
import "../../config" as ConfigModule
import "components" as Components

Scope {
    id: root
    property bool open: false

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.open = !root.open }
        function show(): void { root.open = true }
        function hide(): void { root.open = false }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            focusable: true
            color: "transparent"

            property int openMargin: 0

            implicitWidth: 1150
            implicitHeight: 360

            anchors {
                bottom: true
            }

            exclusiveZone: 0
            margins.bottom: -win.implicitHeight

            Behavior on margins.bottom {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Component.onCompleted: margins.bottom = win.openMargin

            Shortcut {
                sequence: "Escape"
                onActivated: root.open = false
            }

            Rectangle {
                id: content
                anchors.fill: parent
                radius: 16
                bottomLeftRadius: 0
                bottomRightRadius: 0
                clip: true
                color: ConfigModule.Theme.background

                Components.BrowseView {
                    anchors.fill: parent
                }
            }
        }
    }
}
