.pragma library

function levenshtein(a, b) {
    const m = a.length, n = b.length
    if (m === 0) return n
    if (n === 0) return m
    let prev = new Array(n + 1)
    let curr = new Array(n + 1)
    for (let j = 0; j <= n; j++) prev[j] = j
    for (let i = 1; i <= m; i++) {
        curr[0] = i
        for (let j = 1; j <= n; j++) {
            const cost = a[i - 1] === b[j - 1] ? 0 : 1
            curr[j] = Math.min(curr[j - 1] + 1, prev[j] + 1, prev[j - 1] + cost)
        }
        const tmp = prev; prev = curr; curr = tmp
    }
    return prev[n]
}

// quanto maior o score, melhor o match. -1 = sem match.
function score(query, text) {
    if (!query) return 0
    const q = query.toLowerCase()
    const t = text.toLowerCase()

    if (t.startsWith(q)) return 1000 - t.length
    if (t.includes(q)) return 500 - t.indexOf(q)

    // subsequence: letras da query aparecem em ordem no texto
    let qi = 0
    for (let i = 0; i < t.length && qi < q.length; i++) {
        if (t[i] === q[qi]) qi++
    }
    if (qi === q.length) return 200

    // tolerância a erro de digitação (distância de edição)
    const window = t.slice(0, q.length + 2)
    const dist = levenshtein(q, window)
    const threshold = Math.max(1, Math.floor(q.length / 3))
    if (dist <= threshold) return 100 - dist

    return -1
}
