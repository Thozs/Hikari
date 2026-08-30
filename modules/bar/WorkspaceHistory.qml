pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root
    property var history: ({})

    function appIdFor(wsId) {
        return root.history[wsId] || null
    }

    // Reconstroi o historico do zero a partir do snapshot mais recente do
    // Hyprland. So funciona logo apos Hyprland.refreshToplevels() completar
    // (por isso o delay antes de chamar), porque lastIpcObject so atualiza
    // com um fetch explicito.
    function rebuildFromSnapshot() {
        const all = [...Hyprland.toplevels.values]
        const byWs = {}
        for (const t of all) {
            const ipc = t.lastIpcObject
            if (!ipc || !ipc.class || !ipc.workspace) continue
            const wsId = ipc.workspace.id
            const fhid = ipc.focusHistoryID !== undefined ? ipc.focusHistoryID : 999999
            if (!(wsId in byWs) || fhid < byWs[wsId].fhid) {
                byWs[wsId] = { fhid: fhid, appId: ipc.class }
            }
        }
        const updated = {}
        for (const wsId in byWs) updated[wsId] = byWs[wsId].appId
        root.history = updated
    }

    function requestRefresh() {
        refreshTimer.restart()
    }

    Component.onCompleted: requestRefresh()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const relevant = ["movewindow", "workspace", "activewindow", "openwindow", "closewindow", "focusedmon"]
            if (relevant.some(prefix => event.name.startsWith(prefix))) {
                root.requestRefresh()
            }
        }
    }

    // debounce: varios eventos costumam chegar juntos (ex: movewindow +
    // activewindow), entao espera um pouco antes de disparar o refresh real
    Timer {
        id: refreshTimer
        interval: 80
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels()
            reseedTimer.start()
        }
    }

    // da tempo do refreshToplevels() (assincrono) terminar antes de ler
    Timer {
        id: reseedTimer
        interval: 80
        repeat: false
        onTriggered: root.rebuildFromSnapshot()
    }
}
