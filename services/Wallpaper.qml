pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ---- Wallhaven ----
    property bool fetching: false
    property var currentResults: []
    property string lastError: ""
    property string currentQuery: ""
    property int currentPage: 1
    property int lastPage: 1
    property string sorting: "relevance"
    property string order: "desc"
    property string categories: "111"
    property string purity: "100"

    readonly property string apiBaseUrl: "https://wallhaven.cc/api/v1"
    readonly property string apiKey: Quickshell.env("ARNYX_WALLHAVEN_API_KEY") || ""

    readonly property string wallsDir: Quickshell.env("HOME") + "/Imagens/Wallpapers"
    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/arnyx-wallpapers"

    property var localList: []
    property bool localScanned: false
    property string appliedPath: ""

    signal wallpaperApplied(string path)
    signal searchFailed(string error)
    signal originalReady(string wallpaperId, string filename)

    property string resizeTool: ""
    Process {
        id: resizeToolCheck
        command: ["sh", "-c", "command -v magick || command -v convert"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.resizeTool = text.trim().split("\n")[0] || ""
                if (root.resizeTool === "")
                    console.warn("[Wallpaper] magick/convert nao encontrado — resize de resolucao vai falhar.")
            }
        }
    }

    function scanLocal() { localScanProc.running = true }

    Process {
        id: localScanProc
        command: ["sh", "-c",
            "mkdir -p '" + root.wallsDir + "' && find '" + root.wallsDir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) " +
            "-printf '%T@\\t%f\\t%p\\n' | sort -rn"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.length > 0)
                root.localList = lines.map(l => {
                    const parts = l.split("\t")
                    return { name: parts[1], path: parts[2], modified: parseFloat(parts[0]) }
                })
                root.localScanned = true
                console.log("[Wallpaper] scanLocal: " + root.localList.length + " wallpapers encontrados")
            }
        }
    }

    Component.onCompleted: scanLocal()

    function deleteLocalPaths(paths) {
        if (!paths || paths.length === 0) return
        const quoted = paths.map(p => "'" + p.replace(/'/g, "'\\''") + "'").join(" ")
        deleteProc.command = ["sh", "-c", "rm -f -- " + quoted]
        deleteProc.running = true
    }

    Process {
        id: deleteProc
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("[Wallpaper] erro ao apagar:", text.trim())
        }
        onExited: (exitCode) => {
            root.scanLocal()
        }
    }

    function search(query, page) {
        if (fetching) return
        fetching = true
        lastError = ""
        currentQuery = query || ""
        currentPage = page || 1

        const params = []
        if (currentQuery) params.push("q=" + encodeURIComponent(currentQuery))
        params.push("categories=" + categories)
        params.push("purity=" + purity)
        params.push("sorting=" + sorting)
        params.push("order=" + order)
        if (apiKey) params.push("apikey=" + apiKey)
        params.push("page=" + currentPage)

        const url = apiBaseUrl + "/search?" + params.join("&")
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                fetching = false
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText)
                        currentResults = response.data || []
                        lastPage = (response.meta && response.meta.last_page) || 1
                    } catch (e) {
                        lastError = "Falha ao processar resposta da API"
                        searchFailed(lastError)
                    }
                } else if (xhr.status === 429) {
                    lastError = "Limite de requisicoes excedido (45/min)"
                    searchFailed(lastError)
                } else {
                    lastError = "Erro da API: " + xhr.status
                    searchFailed(lastError)
                }
            }
        }
        xhr.open("GET", url)
        xhr.send()
    }

    function nextPage() { if (currentPage < lastPage && !fetching) search(currentQuery, currentPage + 1) }
    function previousPage() { if (currentPage > 1 && !fetching) search(currentQuery, currentPage - 1) }

    function getThumbnailUrl(wallpaper, size) {
        if (wallpaper.thumbs && wallpaper.thumbs[size]) return wallpaper.thumbs[size]
        return ""
    }

    function getFullUrl(wallpaper) { return wallpaper.path || "" }

    property string _pendingApplyPath: ""
    property string _pendingFitMode: "cover"

    Process {
        id: applyProc
        stdout: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.log("[Wallpaper] stdout:", text.trim())
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.warn("[Wallpaper] stderr:", text.trim())
        }
        onExited: (exitCode) => {
            if (exitCode === 0) {
                console.log("[Wallpaper] aplicado com sucesso:", root._pendingApplyPath)
                root._saveAppliedState(root._pendingApplyPath, root._pendingFitMode)
                root.appliedPath = root._pendingApplyPath
                root.wallpaperApplied(root._pendingApplyPath)
            } else {
                root.lastError = "hyprctl saiu com codigo " + exitCode
                console.warn("[Wallpaper]", root.lastError)
                root.searchFailed(root.lastError)
            }
        }
    }

    function applyPath(path, fitMode) {
        root._pendingApplyPath = path
        const fm = fitMode || "cover"
        root._pendingFitMode = fm
        const cmd = "hyprctl hyprpaper wallpaper '," + path + "," + fm + "'"
        console.log("[Wallpaper] aplicando:", path)
        applyProc.command = ["sh", "-c", cmd]
        applyProc.running = true
    }

    function _resizeCmd(srcPath, outPath, width, height, fillMode) {
        const tool = "'" + resizeTool + "'"
        if (fillMode === 0)
            return tool + " '" + srcPath + "' -resize " + width + "x" + height + " -background black -gravity center -extent " + width + "x" + height + " '" + outPath + "'"
        if (fillMode === 4)
            return tool + " '" + srcPath + "' -resize " + width + "x" + height + "! '" + outPath + "'"
        return tool + " '" + srcPath + "' -resize " + width + "x" + height + "^ -gravity center -extent " + width + "x" + height + " '" + outPath + "'"
    }

    function applyWithResize(srcPath, width, height, fillMode) {
        if (!width || !height || resizeTool === "") {
            applyPath(srcPath)
            return
        }
        const outPath = cacheDir + "/applied_" + width + "x" + height + ".jpg"
        const cmdFixed = "mkdir -p '" + cacheDir + "' && " + _resizeCmd(srcPath, outPath, width, height, fillMode) +
            " && hyprctl hyprpaper wallpaper '," + outPath + ",cover'"
        root._pendingApplyPath = outPath
        root._pendingFitMode = "cover"
        console.log("[Wallpaper] aplicando com resize:", outPath)
        applyProc.command = ["sh", "-c", cmdFixed]
        applyProc.running = true
    }

    function downloadOnly(wallpaper, width, height, fillMode, label) {
        const url = getFullUrl(wallpaper)
        if (!url) return
        const tmpPath = cacheDir + "/wallhaven_" + wallpaper.id + "_orig.jpg"
        const outPath = wallsDir + "/wallhaven_" + wallpaper.id + "_" + (label || (width + "x" + height)) + ".jpg"
        const cmd = "mkdir -p '" + cacheDir + "' '" + wallsDir + "' && curl -L -s -o '" + tmpPath + "' '" + url + "'"
        const proc = downloadOnlyComp.createObject(root, {
            command: ["sh", "-c", cmd], tmpPath: tmpPath, outPath: outPath,
            width: width, height: height, fillMode: fillMode
        })
        proc.running = true
    }

    Component {
        id: downloadOnlyComp
        Process {
            property string tmpPath: ""
            property string outPath: ""
            property int width: 0
            property int height: 0
            property int fillMode: 1
            onExited: (exitCode) => {
                if (exitCode === 0 && root.resizeTool !== "") {
                    const cmd = root._resizeCmd(tmpPath, outPath, width, height, fillMode) + " && rm -f '" + tmpPath + "'"
                    Quickshell.execDetached(["sh", "-c", cmd])
                    // Atualiza a lista local após salvar
                    root.scanLocal()
                }
                destroy()
            }
        }
    }

    function downloadOriginal(wallpaper) {
        const url = getFullUrl(wallpaper)
        if (!url) return
        const extMatch = url.match(/\.([a-zA-Z0-9]+)$/)
        const ext = extMatch ? extMatch[1] : "jpg"
        const filename = "wallhaven_" + wallpaper.id + "." + ext
        const outPath = wallsDir + "/" + filename

        // Sempre baixa (sobrescreve se já existe) - mais simples e confiável
        const cmd = "mkdir -p '" + wallsDir + "' && curl -L -s -o '" + outPath + "' '" + url + "'"
        const proc = downloadOriginalComp.createObject(root, {
            command: ["sh", "-c", cmd], filename: filename, wallpaperId: wallpaper.id
        })
        proc.running = true
    }

    Component {
        id: downloadOriginalComp
        Process {
            property string filename: ""
            property string wallpaperId: ""
            onExited: (exitCode) => {
                if (exitCode === 0) {
                    root.scanLocal()
                    root.originalReady(wallpaperId, filename)
                } else {
                    root.lastError = "Falha ao baixar wallpaper (exit " + exitCode + ")"
                    console.warn("[Wallpaper]", root.lastError)
                    root.searchFailed(root.lastError)
                }
                destroy()
            }
        }
    }

    function downloadAndApply(wallpaper, width, height, fillMode) {
        const url = getFullUrl(wallpaper)
        if (!url) return
        const tmpPath = cacheDir + "/wallhaven_" + wallpaper.id + "_orig.jpg"
        const cmd = "mkdir -p '" + cacheDir + "' && curl -L -s -o '" + tmpPath + "' '" + url + "'"
        const proc = downloadApplyComp.createObject(root, {
            command: ["sh", "-c", cmd], tmpPath: tmpPath,
            width: width || 0, height: height || 0, fillMode: fillMode || 1,
            wallpaperId: wallpaper.id, wallpaperUrl: url
        })
        proc.running = true
    }

    Component {
        id: downloadApplyComp
        Process {
            property string tmpPath: ""
            property int width: 0
            property int height: 0
            property int fillMode: 1
            property string wallpaperId: ""
            property string wallpaperUrl: ""
            onExited: (exitCode) => {
                if (exitCode === 0) {
                    // Salva cópia na pasta local (wallsDir) para aparecer em "Minha Pasta"
                    const extMatch = wallpaperUrl.match(/\.([a-zA-Z0-9]+)$/)
                    const ext = extMatch ? extMatch[1] : "jpg"
                    const localFilename = "wallhaven_" + wallpaperId + "." + ext
                    const localPath = wallsDir + "/" + localFilename
                    const saveCmd = "mkdir -p '" + wallsDir + "' && cp '" + tmpPath + "' '" + localPath + "'"
                    // Usa componente Process reutilizável para cópia síncrona
                    const saveProc = saveLocalComp.createObject(root, { command: ["sh", "-c", saveCmd] })
                    saveProc.running = true

                    if (width > 0 && height > 0)
                        root.applyWithResize(tmpPath, width, height, fillMode)
                    else
                        root.applyPath(tmpPath)
                } else {
                    root.lastError = "Falha ao baixar wallpaper (exit " + exitCode + ")"
                    root.searchFailed(root.lastError)
                }
                destroy()
            }
        }
    }

    Component {
        id: saveLocalComp
        Process {
            onExited: (exitCode) => {
                if (exitCode === 0) {
                    root.scanLocal()
                }
                destroy()
            }
        }
    }

    readonly property string configDir: Quickshell.env("HOME") + "/.config/arnyx-qs"
    readonly property string statePath: root.configDir + "/wallpaper.json"

    property int _retryCount: 0
    readonly property int _retryMaxAttempts: 15
    readonly property int _retryIntervalMs: 1000

    Process {
        id: ensureStateFileProc
        command: ["sh", "-c",
            "mkdir -p '" + root.configDir + "' && [ -f '" + root.statePath + "' ] || printf '%s' '{\"path\":\"\",\"fitMode\":\"cover\"}' > '" + root.statePath + "' ; cat '" + root.statePath + "'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                stateFile.path = root.statePath
                try {
                    const saved = JSON.parse(text)
                    if (saved && saved.path) {
                        root.appliedPath = saved.path
                        root._retryCount = 0
                        root._attemptRestore(saved.path, saved.fitMode || "cover")
                    }
                } catch (e) {
                    console.warn("[Wallpaper] wallpaper.json invalido, ignorando restauracao:", e)
                }
            }
        }
    }

    FileView {
        id: stateFile
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: stateAdapter
            property string path: ""
            property string fitMode: "cover"
        }
    }

    function _saveAppliedState(path, fitMode) {
        if (!stateFile.adapter) {
            console.warn("[Wallpaper] adapter de estado ainda nao pronto, path nao foi salvo pra persistencia")
            return
        }
        stateFile.adapter.path = path
        stateFile.adapter.fitMode = fitMode || "cover"
    }

    function _attemptRestore(path, fitMode) {
        root._retryCount++
        restoreProc._path = path
        restoreProc._fitMode = fitMode
        restoreProc.command = ["sh", "-c", "hyprctl hyprpaper wallpaper '," + path + "," + fitMode + "'"]
        restoreProc.running = true
    }

    Process {
        id: restoreProc
        property string _path: ""
        property string _fitMode: "cover"
        property string _stderrText: ""
        stderr: StdioCollector {
            onStreamFinished: restoreProc._stderrText = text
        }
        onExited: (exitCode) => {
            const looksNotReady = /couldn.?t connect|hyprpaper\.sock/i.test(restoreProc._stderrText)
            const failed = exitCode !== 0 || looksNotReady

            if (!failed) {
                console.log("[Wallpaper] restaurado no boot:", restoreProc._path)
                return
            }

            if (root._retryCount >= root._retryMaxAttempts) {
                console.warn("[Wallpaper] falha ao restaurar apos", root._retryMaxAttempts,
                    "tentativas. ultimo erro:", restoreProc._stderrText.trim())
                return
            }

            restoreRetryTimer.start()
        }
    }

    Timer {
        id: restoreRetryTimer
        interval: root._retryIntervalMs
        repeat: false
        onTriggered: root._attemptRestore(restoreProc._path, restoreProc._fitMode)
    }

    IpcHandler {
        target: "wallpaperservice"
        function testSearch(query: string): string {
            root.search(query, 1)
            return "busca disparada: " + query
        }
    }
}
