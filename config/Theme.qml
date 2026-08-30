pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // =========================================================================
    // CORES FALLBACK (Catppuccin Mocha)
    // =========================================================================
    readonly property color _fixedBackground: "#1e1e2e"
    readonly property color _fixedSurfaceLow: "#181825"
    readonly property color _fixedSurface: "#313244"
    readonly property color _fixedSurfaceHigh: "#45475a"
    readonly property color _fixedSurfaceHighest: "#585b70"
    readonly property color _fixedText: "#cdd6f4"
    readonly property color _fixedTextMuted: "#a6adc8"
    readonly property color _fixedOutline: "#7f849c"
    readonly property color _fixedOutlineVariant: "#6c7086"
    readonly property color _fixedAccent: "#cba6f7"
    readonly property color _fixedAccentText: "#1e1e2e"
    readonly property color _fixedDanger: "#f38ba8"

    // =========================================================================
    // PROPRIEDADES PÚBLICAS
    // =========================================================================
    property bool dynamicColorEnabled: true
    property bool barUseMatugen: true
    property string _wallpaperPath: ""

    // Propriedades expostas (calculadas dinamicamente via matugen ou fallback)
    readonly property color background: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mBackground : root._fixedBackground
    readonly property color surfaceLow: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mSurfaceLow : root._fixedSurfaceLow
    readonly property color surface: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mSurface : root._fixedSurface
    readonly property color surfaceHigh: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mSurfaceHigh : root._fixedSurfaceHigh
    readonly property color surfaceHighest: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mSurfaceHighest : root._fixedSurfaceHighest

    readonly property color text: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mText : root._fixedText
    readonly property color textMuted: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mTextMuted : root._fixedTextMuted

    readonly property color outline: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mOutline : root._fixedOutline
    readonly property color outlineVariant: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mOutlineVariant : root._fixedOutlineVariant

    readonly property color accent: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mAccent : root._fixedAccent
    readonly property color accentText: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mAccentText : root._fixedAccentText

    readonly property color danger: (root.dynamicColorEnabled && root._matugenLoaded) ? root._mDanger : root._fixedDanger

    // Propriedades específicas da bar (respeitam barUseMatugen)
    readonly property color barBackground: (root.barUseMatugen && root._matugenLoaded) ? root._mBackground : root._fixedBackground
    readonly property color barSurfaceLow: (root.barUseMatugen && root._matugenLoaded) ? root._mSurfaceLow : root._fixedSurfaceLow
    readonly property color barSurface: (root.barUseMatugen && root._matugenLoaded) ? root._mSurface : root._fixedSurface
    readonly property color barSurfaceHigh: (root.barUseMatugen && root._matugenLoaded) ? root._mSurfaceHigh : root._fixedSurfaceHigh
    readonly property color barSurfaceHighest: (root.barUseMatugen && root._matugenLoaded) ? root._mSurfaceHighest : root._fixedSurfaceHighest
    readonly property color barText: (root.barUseMatugen && root._matugenLoaded) ? root._mText : root._fixedText
    readonly property color barTextMuted: (root.barUseMatugen && root._matugenLoaded) ? root._mTextMuted : root._fixedTextMuted
    readonly property color barOutline: (root.barUseMatugen && root._matugenLoaded) ? root._mOutline : root._fixedOutline
    readonly property color barOutlineVariant: (root.barUseMatugen && root._matugenLoaded) ? root._mOutlineVariant : root._fixedOutlineVariant
    readonly property color barAccent: (root.barUseMatugen && root._matugenLoaded) ? root._mAccent : root._fixedAccent
    readonly property color barAccentText: (root.barUseMatugen && root._matugenLoaded) ? root._mAccentText : root._fixedAccentText
    readonly property color barDanger: (root.barUseMatugen && root._matugenLoaded) ? root._mDanger : root._fixedDanger

    // =========================================================================
    // ISDARK & DEBUG
    // =========================================================================
    readonly property list<color> wallpaperColors: (root.dynamicColorEnabled && wallpaperQuantizer.colors.length > 0) ? wallpaperQuantizer.colors : []
    readonly property bool isDark: root._computeIsDark(root.wallpaperColors)
    readonly property color wallpaperAccent: root.accent

    // ColorQuantizer mantido apenas para decidir isDark (modo do matugen)
    // depth: 3 = 8 cores (rápido, matugen faz o trabalho pesado de cor)
    ColorQuantizer {
        id: wallpaperQuantizer
        source: (root.dynamicColorEnabled && root._wallpaperPath !== "") ? Qt.resolvedUrl(root._wallpaperPath) : ""
        rescaleSize: 64
        depth: 3
    }

    function _relativeLuminance(c) {
        function channel(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
    }

    function _computeIsDark(colors) {
        if (!colors || colors.length === 0) return true
        let sum = 0
        for (const c of colors) sum += root._relativeLuminance(c)
        const avg = sum / colors.length
        console.log("[Theme] _computeIsDark: colors.length=" + colors.length + " avgLuminance=" + avg + " isDark=" + (avg < 0.5))
        return avg < 0.5
    }

    // =========================================================================
    // INTEGRAÇÃO COM MATUGEN VIA PROCESS
    // =========================================================================
    property bool _matugenLoaded: false

    property color _mBackground
    property color _mSurfaceLow
    property color _mSurface
    property color _mSurfaceHigh
    property color _mSurfaceHighest
    property color _mText
    property color _mTextMuted
    property color _mOutline
    property color _mOutlineVariant
    property color _mAccent
    property color _mAccentText
    property color _mDanger

    // Cache simples: evita rodar matugen de novo pro mesmo wallpaper+mode
    property string _lastMatugenPath: ""
    property bool _lastMatugenIsDark: false

    on_WallpaperPathChanged: root._runMatugen()
    onIsDarkChanged: root._runMatugen()

    function _runMatugen() {
        if (!root.dynamicColorEnabled || root._wallpaperPath === "") return
        // Cache: se path e mode não mudaram, não roda de novo
        if (root._lastMatugenPath === root._wallpaperPath && root._lastMatugenIsDark === root.isDark) {
            console.log("[Theme] matugen cache hit, pulando")
            return
        }
        console.log("[Theme] _runMatugen chamado, path:", root._wallpaperPath, "isDark:", root.isDark)
        matugenProc.running = false
        matugenProc.command = [
            "matugen", "image",
            "--json", "hex",
            "--mode", root.isDark ? "dark" : "light",
            "--type", "scheme-tonal-spot",
            "--source-color-index", "0",
            root._wallpaperPath
        ]
        matugenProc.running = true
    }

    Process {
        id: matugenProc
        stdout: StdioCollector {
            id: matugenOut
            onDataChanged: {
                if (!matugenOut.data) return
                const outText = String(matugenOut.data)
                if (outText.trim() === "" || outText === "undefined") return
                    
                try {
                    const parsed = JSON.parse(outText)
                    const colors = parsed.colors
                    if (!colors) return

                    // Debug: log todas as cores que o matugen retornou
                    console.log("[Theme] matugen colors:", JSON.stringify(colors))

                    // matugen retorna {dark: {color: "#..."}, default: {...}, light: {...}}
                    // Usa o modo correspondente ao --mode passado (dark ou light)
                    const mode = root.isDark ? "dark" : "light"
                    console.log("[Theme] mc() mode:", mode, "isDark:", root.isDark)
                    function mc(key) {
                        const val = colors[key]?.[mode]?.color || colors[key]?.default?.color || "#000000"
                        console.log("[Theme] mc(" + key + ") -> " + val + " (mode=" + mode + ")")
                        return val
                    }

                    root._mBackground = mc("background")
                    root._mSurfaceLow = mc("surface_dim")
                    root._mSurface = mc("surface")
                    root._mSurfaceHigh = mc("surface_container_high")
                    root._mSurfaceHighest = mc("surface_container_highest")
                    root._mText = mc("on_background")
                    root._mTextMuted = mc("outline")
                    root._mOutline = mc("outline_variant")
                    root._mOutlineVariant = mc("surface_variant")
                    root._mAccent = mc("primary")
                    root._mAccentText = mc("on_primary")
                    root._mDanger = mc("error")

                    // Atualiza cache
                    root._lastMatugenPath = root._wallpaperPath
                    root._lastMatugenIsDark = root.isDark

                    root._matugenLoaded = true
                    console.log("[Theme] matugen carregado com sucesso (" + mode + ")")
                    console.log("[Theme] background:", root._mBackground, "accent:", root._mAccent, "text:", root._mText)
                } catch (e) {
                    console.log("[Theme] Erro ao parsear JSON do matugen:", e)
                }
            }
        }
        stderr: StdioCollector {
            id: matugenErr
            onDataChanged: {
                if (matugenErr.data) {
                    const errText = String(matugenErr.data).trim()
                    if (errText !== "") console.log("[Theme] matugen stderr:", errText)
                }
            }
        }
    }
}
