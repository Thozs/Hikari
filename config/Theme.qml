pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property color _fixedBackground: "#1e1e2e"
    readonly property color background:
        (root.dynamicColorEnabled && root.wallpaperColors.length > 0)
            ? root._deriveBackground(root.wallpaperColors, root.isDark)
            : root._fixedBackground
    readonly property color surfaceLow: "#181825"
    readonly property color surface: "#313244"
    readonly property color surfaceHigh: "#45475a"
    readonly property color surfaceHighest: "#585b70"

    readonly property color text: "#cdd6f4"
    readonly property color textMuted: "#a6adc8"

    readonly property color outline: "#7f849c"
    readonly property color outlineVariant: "#6c7086"

    readonly property color accent: "#cba6f7"
    readonly property color accentText: "#1e1e2e"

    readonly property color danger: "#f38ba8"

    // ---- Color-matching automatico (resumo_10 -> implementacao) ----
    // ETAPA 1: extracao + isDark/wallpaperAccent + funcoes de contraste,
    // isolado. Ainda NAO liga em background/text/accent/etc (etapa 2,
    // so apos confirmacao visual/teste desta etapa).

    property bool dynamicColorEnabled: true

    // Recebe o path do wallpaper via Binding em shell.qml (nao importar
    // services/Wallpaper.qml aqui - singleton importando singleton falha
    // com "ReferenceError", ver sessao de implementacao).
    property string _wallpaperPath: ""
    property string _lastColorsSnapshot: ""

    readonly property list<color> wallpaperColors:
        (root.dynamicColorEnabled && wallpaperQuantizer.colors.length > 0)
            ? wallpaperQuantizer.colors : []

    readonly property bool isDark: root._computeIsDark(root.wallpaperColors)

    readonly property color wallpaperAccent: root._pickAccent(root.wallpaperColors)

    ColorQuantizer {
        id: wallpaperQuantizer
        // rescaleSize baixo (64px) e depth 3 (8 cores): custo baixo pro
        // hardware fraco (i5-3470/HD 2500), ver aviso de trade-off dado
        // antes de implementar.
        source: (root.dynamicColorEnabled && root._wallpaperPath !== "")
            ? Qt.resolvedUrl(root._wallpaperPath) : ""
        rescaleSize: 64
        depth: 3
        onColorsChanged: {
            const snapshot = JSON.stringify(wallpaperQuantizer.colors.map(c => c.toString()))
            if (snapshot === root._lastColorsSnapshot) return
            root._lastColorsSnapshot = snapshot
            root._logDebug()
        }
    }

    function _relativeLuminance(c) {
        function channel(v) { return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b)
    }

    function _contrastRatio(c1, c2) {
        const l1 = root._relativeLuminance(c1)
        const l2 = root._relativeLuminance(c2)
        const lighter = Math.max(l1, l2)
        const darker = Math.min(l1, l2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    function _computeIsDark(colors) {
        if (!colors || colors.length === 0) return true
        let sum = 0
        for (const c of colors) sum += root._relativeLuminance(c)
        return (sum / colors.length) < 0.5
    }

    // Piso minimo de saturacao (0-1). Abaixo disso, a cor mais "vibrante"
    // extraida ainda assim fica apagada demais pra servir de accent -> cai
    // pro accent fixo do Catppuccin em vez de usar uma cor sem graca.
    readonly property real _minAccentSaturation: 0.35

    // ETAPA 2 (teste inicial): so background vira dinamico por enquanto.
    // Pega a cor mais escura (isDark) ou mais clara (!isDark) das extraidas,
    // depois garante 4.5:1 contra o "text" fixo reaproveitando
    // contrastAdjusted (aqui o candidato a background e' o lado ajustavel,
    // "text" fixo e' a referencia).
    // Piso mais baixo que o do accent: o fundo ja sai com saturacao
    // reduzida (ver abaixo), entao aceita hues mais sutis sem ficar feio.
    readonly property real _minBackgroundSaturation: 0.15

    function _deriveBackground(colors, isDark) {
        // Media ponderada de matiz (vetor circular): cada cor contribui
        // proporcional a propria saturacao. Uma faixa fina bem saturada
        // (ex: um detalhe rosa isolado) nao domina mais sobre uma massa
        // grande de tons proximos (ex: varios tons de ciano) - e o oposto
        // do approach anterior, que pegava so "a cor mais saturada" isolada
        // e podia escolher um detalhe pequeno em vez da cor dominante real.
        let vx = 0, vy = 0, totalSat = 0
        for (const c of colors) {
            const s = c.hslSaturation
            const h = c.hslHue * 2 * Math.PI
            vx += Math.cos(h) * s
            vy += Math.sin(h) * s
            totalSat += s
        }
        const avgSat = totalSat / colors.length
        if (avgSat < root._minBackgroundSaturation) {
            // wallpaper dessaturado demais (preto/cinza/branco dominando) -
            // sem hue confiavel pra seguir, mantem o fundo fixo.
            return root._fixedBackground
        }
        const avgHue = (Math.atan2(vy, vx) / (2 * Math.PI) + 1) % 1

        // Luminosidade media das cores extraidas (aproximacao sem peso por
        // pixel - limitacao conhecida do ColorQuantizer, ver conversa).
        let avgL = 0
        for (const c of colors) avgL += c.hslLightness
        avgL /= colors.length

        // Curva quadratica em vez de linear: satura??o baixa/moderada
        // (ex: wallpaper quase branco com um icone escuro pequeno,
        // que "contamina" a media com alguma saturacao mesmo sem ser
        // dominante de verdade) e' suprimida com forca; saturacao alta
        // de verdade (ex: cabelo bem saturado) continua passando forte -
        // isso tambem da' o efeito de "mais brilho" em wallpapers vividos.
        const satWeight = Math.pow(Math.min(1, avgSat), 2)

        const rawTarget = isDark
            ? Math.min(0.38, Math.max(0.10, avgL * 0.55 + satWeight * 0.10))
            : Math.min(0.97, Math.max(0.75, 0.6 + avgL * 0.35))

        // Ancora quase-puro preto/branco - satWeight baixo puxa forte pra
        // ca, satWeight alto deixa o rawTarget (a cor real derivada) dominar.
        const anchorLightness = isDark ? 0.09 : 0.97
        const targetLightness = anchorLightness * (1 - satWeight) + rawTarget * satWeight

        // saturacao final tambem usa a curva suprimida, com teto um pouco
        // mais alto (0.9) pra wallpapers bem vividos poderem "brilhar" mais.
        const derived = Qt.hsla(avgHue, satWeight * 0.9, targetLightness, 1.0)
        return root.contrastAdjusted(derived, root.text, 4.5)
    }

    function _pickAccent(colors) {
        if (!colors || colors.length === 0) return root.accent
        let best = colors[0]
        let bestSat = -1
        for (const c of colors) {
            if (c.hslSaturation > bestSat) {
                bestSat = c.hslSaturation
                best = c
            }
        }
        if (bestSat < root._minAccentSaturation) return root.accent
        return best
    }

    // Pronta pra etapa 2 (aplicar em text/accentText quando virarem
    // calculados) - ainda nao usada em nenhuma property derivada.
    function contrastAdjusted(foreground, background, minRatio) {
        if (root._contrastRatio(foreground, background) >= minRatio) return foreground
        const lighten = root._relativeLuminance(background) < 0.5
        let l = foreground.hslLightness
        let adjusted = foreground
        let steps = 0
        while (root._contrastRatio(adjusted, background) < minRatio && steps < 20) {
            l = lighten ? Math.min(1, l + 0.05) : Math.max(0, l - 0.05)
            adjusted = Qt.hsla(foreground.hslHue, foreground.hslSaturation, l, foreground.a)
            steps++
        }
        return adjusted
    }

    function _logDebug() {
        console.log("[Theme] wallpaperColors:", JSON.stringify(root.wallpaperColors.map(c => c.toString())))
        console.log("[Theme] isDark:", root.isDark, "| wallpaperAccent:", root.wallpaperAccent.toString())
        console.log("[Theme] contraste text/background (fixo, referencia):",
            root._contrastRatio(root.text, root.background).toFixed(2))
        console.log("[Theme] contraste accentText/accent (fixo, referencia):",
            root._contrastRatio(root.accentText, root.accent).toFixed(2))
    }
}
