pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property real maxVolume: 1.0
    readonly property real volumeStep: 0.05

    property list<PwNode> sinks: []
    property list<PwNode> sources: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    function setVolume(v: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(root.maxVolume, v));
        }
    }

    function setSourceVolume(v: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(root.maxVolume, v));
        }
    }

    function toggleMute(): void {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function toggleSourceMute(): void {
        if (source?.ready && source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    function setAudioSink(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setAudioSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    Connections {
        target: Pipewire.nodes
        function onValuesChanged(): void {
            const newSinks = [];
            const newSources = [];
            for (const node of Pipewire.nodes.values) {
                if (node.isStream)
                    continue;
                if (node.isSink)
                    newSinks.push(node);
                else if (node.audio)
                    newSources.push(node);
            }
            root.sinks = newSinks;
            root.sources = newSources;
        }
    }

    PwObjectTracker {
        objects: [...root.sinks, ...root.sources]
    }

    IpcHandler {
        target: "audio"

        function incrementVolume(): void {
            root.setVolume(root.volume + root.volumeStep);
        }

        function decrementVolume(): void {
            root.setVolume(root.volume - root.volumeStep);
        }

        function toggleMute(): void {
            root.toggleMute();
        }

        function incrementSourceVolume(): void {
            root.setSourceVolume(root.sourceVolume + root.volumeStep);
        }

        function decrementSourceVolume(): void {
            root.setSourceVolume(root.sourceVolume - root.volumeStep);
        }

        function toggleSourceMute(): void {
            root.toggleSourceMute();
        }
    }
}
