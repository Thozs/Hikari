import QtQuick
import Quickshell
import "../../config"

Item {
    id: root
    required property int thickness

    readonly property int iconSize: Math.round(thickness * 0.55)
    // Ícones monocromáticos (symbolic) - usamos como estão, o fundo do módulo dá contraste
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

    // Cursor de ponteiro (mão) para indicar que é clicável
    cursorShape: Qt.PointingHandCursor

    Image {
        id: archIcon
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        visible: root.iconSrc !== ""
        source: root.iconSrc
        // Ícones symbolic são monocromáticos (branco com transparência) - funcionam no fundo escuro do módulo
    }

    Text {
        anchors.centerIn: parent
        visible: root.iconSrc === ""
        text: "🐧"
        color: Theme.barText
        font.pixelSize: Math.round(root.thickness * 0.34)
    }

    TapHandler {
        onTapped: {
            console.log("[LauncherButton] Toggle launcher via IPC")
            Quickshell.execDetached(["quickshell", "ipc", "-c", "arnyx-qs", "call", "launcher", "toggle"])
        }
    }
}
