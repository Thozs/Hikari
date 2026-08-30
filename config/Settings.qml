pragma Singleton
import Quickshell
import QtQuick
Singleton {
    id: root
    // "top" | "bottom" | "left" | "right"
    property string barPosition: "left"

    // Espessura da barra: proporcional a altura de CADA monitor
    // (screen.height * barThicknessRatio), com um chao minimo pra nao ficar
    // fina demais em monitores pequenos.
    property real barThicknessRatio: 0.045
    property int barThicknessMin: 44
    property int barThicknessMax: 64

    // Distancia fixa da borda do monitor no lado "curto" (ex: esquerda,
    // numa barra vertical na esquerda).
    property int barMargin: 14

    // Inset proporcional nas pontas do comprimento da pilula (topo/base numa
    // barra vertical, esquerda/direita numa horizontal).
    property real barVerticalInsetRatio: 0.03

}
