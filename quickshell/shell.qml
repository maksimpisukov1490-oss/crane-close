import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Оверлей закрытия окна: страница складывается в бумажного журавлика
// и улетает. Управление:
//   qs ipc -p ~/.config/quickshell/crane call crane animate '<json>'
ShellRoot {
    id: root

    property var req: null
    property int seq: 0

    function animate(payload) {
        try {
            const data = JSON.parse(payload);
            if (!data || !data.path || !data.monitor)
                return "bad";
            root.req = data;
            root.seq++;
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
            root.req = null;
            root.seq++;
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
            req: root.req
            seq: root.seq
        }
    }
}
