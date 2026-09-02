import QtQuick
import Quickshell
import Qt5Compat.GraphicalEffects
import "../../config"

Item {
    id: root
    required property int thickness

    readonly property int iconSize: Math.round(thickness * 0.55)
    // SVG local (Simple Icons, single-path) - tingido via ColorOverlay com a cor do matugen
    readonly property string iconSrc: Qt.resolvedUrl("../../assets/archlinux-symbolic.svg")

    implicitWidth: Math.round(thickness * 0.6)
    implicitHeight: Math.round(thickness * 0.6)

    Image {
        id: archIcon
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.iconSrc
        sourceSize.width: root.iconSize
        sourceSize.height: root.iconSize
        visible: false
        smooth: true
        antialiasing: true
    }

    ColorOverlay {
        anchors.fill: archIcon
        source: archIcon
        color: Theme.barAccent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            console.log("[LauncherButton] Toggle launcher via IPC")
            Quickshell.execDetached(["quickshell", "ipc", "-c", "hikari", "call", "launcher", "toggle"])
        }
    }
}
