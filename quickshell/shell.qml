import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Оверлей закрытия окна: страница складывается в бумажного журавлика
// и улетает. Можно закрывать несколько окон подряд — журавликов будет
// столько же, каждый со своим окном.
ShellRoot {
    id: root

    property int nextId: 1
    property var reqs: []
    property int reqSeq: 0

    function animate(payload) {
        try {
            const data = JSON.parse(payload);
            if (!data || !data.path || !data.monitor)
                return "bad";
            data.id = root.nextId++;
            root.reqs = root.reqs.concat([data]).slice(-30);
            root.reqSeq++;
            return "ok";
        } catch (e) {
            console.log("crane: bad payload:", e);
            return "bad";
        }
    }

    IpcHandler {
        target: "crane"

        function animate(payload: string): string {
            return root.animate(payload);
        }

        function reset(): void {
            root.nextId++;
            root.reqSeq++;
        }

        function ping(): string {
            return "pong";
        }
    }

    Variants {
        model: Quickshell.screens

        CraneOverlay {
            required property ShellScreen modelData

            screen: modelData
            requests: root.reqs
            reqSeq: root.reqSeq
        }
    }
}
