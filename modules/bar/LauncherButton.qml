import QtQuick
import Quickshell
import "../../config"

Item {
    id: root
    required property int thickness

    readonly property int iconSize: Math.round(thickness * 0.55)
    // Ícones monocromáticos (symbolic) que podem ser tingidos via color
    readonly property var iconCandidates: [
        "archlinux-logo-symbolic",
        "archlinux-symbolic",
        "distributor-logo-archlinux-symbolic",
        "start-here-arch-symbolic",
        "archlinux-logo",
        "archlinux",
        "distributor-logo-archlinux",
        "start-here-arch"
    ]
    readonly property string iconSrc: {
        for (const name of iconCandidates) {
            const p = Quickshell.iconPath(name, true)
            if (p !== "") return p
        }
        return ""
    }

    implicitWidth: Math.round(thickness * 0.6)
    implicitHeight: Math.round(thickness * 0.6)

    Image {
        id: archIcon
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        visible: root.iconSrc !== ""
        source: root.iconSrc
        // Tinge o ícone monocromático com uma cor ligeiramente mais escura que o texto da bar
        color: root.iconSrc.indexOf("-symbolic") !== -1 ? Theme.barText : "transparent"
    }

    Text {
        anchors.centerIn: parent
        visible: root.iconSrc === "" || root.iconSrc.indexOf("-symbolic") === -1
        text: "🐧"
        color: Theme.barText
        font.pixelSize: Math.round(root.thickness * 0.34)
    }

    TapHandler {
        onTapped: Quickshell.execDetached(["quickshell", "ipc", "-c", "arnyx-qs", "call", "launcher", "toggle"])
    }
}
