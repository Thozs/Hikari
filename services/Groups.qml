pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/arnyx-qs"
    readonly property string groupsPath: root.configDir + "/groups.json"
    property bool ready: false

    // dado "vivo" que a UI deve usar (reagir a mudancas daqui)
    property var groups: ({})

    // garante que a pasta e o arquivo existem ANTES do FileView tentar ler,
    // pra nao gerar warning de "File does not exist" no log
    Process {
        id: ensureFileProc
        command: ["sh", "-c",
            "mkdir -p '" + root.configDir + "' && [ -f '" + root.groupsPath + "' ] || printf '%s' '{\"groups\":{}}' > '" + root.groupsPath + "'"]
        running: true
        onExited: (exitCode) => {
            groupsFile.path = root.groupsPath
            root.ready = true
        }
    }

    FileView {
        id: groupsFile
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: jsonAdapter
            property var groups: ({})
            onGroupsChanged: root.groups = jsonAdapter.groups
        }
    }

    function _commit(updated) {
        root.groups = updated
        if (groupsFile.adapter)
            groupsFile.adapter.groups = updated
    }

    // ---- leitura ----

    function groupNames() {
        return Object.keys(root.groups).sort(function (a, b) { return a.localeCompare(b) })
    }

    function groupCount() {
        return Object.keys(root.groups).length
    }

    function contentsOf(name) {
        return root.groups[name] || []
    }

    function groupsForFile(filename) {
        const names = []
        const g = root.groups
        for (const k of Object.keys(g)) {
            if (g[k].indexOf(filename) !== -1)
                names.push(k)
        }
        return names
    }

    // ---- gerenciamento de grupos ----

    function createGroup(name) {
        name = (name || "").trim()
        const g = root.groups
        if (name.length === 0 || Object.prototype.hasOwnProperty.call(g, name))
            return false
        const updated = Object.assign({}, g)
        updated[name] = []
        _commit(updated)
        return true
    }

    function renameGroup(oldName, newName) {
        newName = (newName || "").trim()
        const g = root.groups
        if (!g[oldName] || newName.length === 0)
            return false
        if (newName !== oldName && Object.prototype.hasOwnProperty.call(g, newName))
            return false
        const updated = {}
        for (const k of Object.keys(g))
            updated[k === oldName ? newName : k] = g[k]
        _commit(updated)
        return true
    }

    function deleteGroup(name) {
        const g = root.groups
        if (!g[name])
            return
        const updated = Object.assign({}, g)
        delete updated[name]
        _commit(updated)
    }

    function mergeGroups(names, targetName) {
        targetName = (targetName || "").trim()
        if (!names || names.length < 2 || targetName.length === 0)
            return false
        const g = root.groups
        for (const n of names)
            if (!g[n]) return false
        const union = []
        for (const n of names)
            for (const f of g[n])
                if (union.indexOf(f) === -1) union.push(f)
        const updated = Object.assign({}, g)
        for (const n of names)
            delete updated[n]
        updated[targetName] = union
        _commit(updated)
        return true
    }

    // ---- conteudo dos grupos ----

    function addManyToGroup(name, filenames) {
        const g = root.groups
        if (!g[name]) return
        const merged = g[name].slice()
        filenames.forEach(function (f) { if (merged.indexOf(f) === -1) merged.push(f) })
        const updated = Object.assign({}, g)
        updated[name] = merged
        _commit(updated)
    }

    function addToGroup(name, filename) {
        root.addManyToGroup(name, [filename])
    }

    function removeManyFromGroup(name, filenames) {
        const g = root.groups
        if (!g[name]) return
        const updated = Object.assign({}, g)
        updated[name] = g[name].filter(function (f) { return filenames.indexOf(f) === -1 })
        _commit(updated)
    }

    function removeFromGroup(name, filename) {
        root.removeManyFromGroup(name, [filename])
    }

    function moveFiles(fromGroup, toGroup, filenames) {
        if (fromGroup === toGroup) return
        const g = root.groups
        if (!g[fromGroup] || !g[toGroup]) return
        const updated = Object.assign({}, g)
        updated[fromGroup] = g[fromGroup].filter(function (f) { return filenames.indexOf(f) === -1 })
        const merged = g[toGroup].slice()
        filenames.forEach(function (f) { if (merged.indexOf(f) === -1) merged.push(f) })
        updated[toGroup] = merged
        _commit(updated)
    }

    function copyFiles(toGroup, filenames) {
        root.addManyToGroup(toGroup, filenames)
    }
}
