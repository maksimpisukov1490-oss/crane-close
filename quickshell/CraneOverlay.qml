import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Wayland
import QtQuick3D
import QtQuick3D.Helpers

// Один оверлей на монитор. Держит список активных анимаций: можно
// закрывать окна подряд, у каждого будет свой журавлик.
PanelWindow {
    id: win

    property var requests: null
    property int reqSeq: 0
    property int lastId: 0

    readonly property real tFly: 0.82
    readonly property real tEnd: 2.15

    visible: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "crane"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    mask: Region {}

    ListModel {
        id: anims
    }

    Timer {
        interval: 16
        repeat: true
        running: anims.count > 0
        onTriggered: win.tick()
    }

    onRequestsChanged: drain()
    onReqSeqChanged: drain()

    function drain() {
        if (!requests)
            return;
        let maxId = lastId;
        for (let i = 0; i < requests.length; i++) {
            const r = requests[i];
            if (!r || r.id <= lastId)
                continue;
            maxId = Math.max(maxId, r.id);
            if (r.monitor !== (screen ? screen.name : ""))
                continue;
            addAnim(r);
        }
        lastId = maxId;
    }

    function addAnim(r) {
        const dir = r.dir ? (r.dir < 0 ? -1 : 1) : (Math.random() < 0.5 ? -1 : 1);
        const up = 0.55 + Math.random() * 0.35;
        if (anims.count >= 6)
            anims.remove(0);
        anims.append({
            rid: r.id,
            path: r.path,
            wx: r.x,
            wy: r.y,
            ww: r.w,
            wh: r.h,
            dir: dir,
            up: up,
            t: 0,
            t0: Date.now()
        });
    }

    function tick() {
        const now = Date.now();
        for (let i = anims.count - 1; i >= 0; i--) {
            const row = anims.get(i);
            const t = (now - row.t0) / 1000;
            if (t >= tEnd)
                anims.remove(i);
            else
                anims.setProperty(i, "t", t);
        }
    }

    // ---------- расчёты ----------

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }
    function smooth(v) {
        const x = clamp(v);
        return x * x * (3 - 2 * x);
    }

    function bloomAt(t) {
        return smooth(clamp((t - 0.34) / 0.46));
    }

    function flyAt(t) {
        const q = clamp((t - tFly) / (tEnd - tFly));
        return Math.pow(q, 1.18);
    }

    function flapAt(t) {
        if (t < 0.70)
            return 0;
        const w = Math.min(1, (t - 0.70) / 0.18);
        return Math.sin((t - 0.70) * 11.0) * 24 * w;
    }

    function craneScaleFor(ww, wh) {
        return Math.max(0.28, Math.min(1.6, Math.min(ww, wh) / 600));
    }

    function birdPos(wx, wy, ww, wh, dir, up, t) {
        const e = flyAt(t);
        const pcx = wx + ww / 2 - width / 2;
        const pcy = height / 2 - (wy + wh / 2);
        return Qt.vector3d(pcx + dir * e * Math.min(ww * 0.75, 980),
                           pcy + e * up * Math.min(wh * 0.55, 520),
                           e * 330);
    }

    function birdRot(t, dir) {
        const e = flyAt(t);
        return Qt.vector3d(-6 * e, -dir * (8 + 16 * e), -dir * (8 + 22 * e));
    }

    // ---------- 3D ----------

    View3D {
        anchors.fill: parent
        visible: anims.count > 0

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Transparent
            clearColor: "transparent"
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 0, 1200)
            fieldOfView: 2 * Math.atan((win.height / 2) / 1200) * 180 / Math.PI
        }

        Repeater3D {
            model: anims

            Node {
                id: birdNode

                required property int index
                required property real wx
                required property real wy
                required property real ww
                required property real wh
                required property int dir
                required property real up
                required property real t
                required property string path
                required property int rid

                position: win.birdPos(wx, wy, ww, wh, dir, up, t)
                eulerRotation: win.birdRot(t, dir)
                visible: t > 0.28

                Crane3D {
                    shotUrl: "file://" + path
                    bloom: win.bloomAt(t)
                    mirrored: dir < 0
                    flap: win.flapAt(t)
                    scale: {
                        const s = win.craneScaleFor(ww, wh);
                        return Qt.vector3d(s, s, s);
                    }
                }
            }
        }
    }

    // ---------- листы со скриншотами ----------

    Repeater {
        model: anims

        Item {
            id: pageItem

            required property int index
            required property real wx
            required property real wy
            required property real ww
            required property real wh
            required property real t
            required property string path

            readonly property real q: win.smooth(win.clamp((t - 0.30) / 0.26))
            readonly property real cut: Math.min(width, height) * (0.02 + 0.30 * q)

            x: wx
            y: wy
            width: ww
            height: wh
            visible: t < 0.62
            transformOrigin: Item.Center
            scale: 1 - 0.95 * q
            rotation: -9 * q
            opacity: q < 0.75 ? 1 : Math.max(0, 1 - (q - 0.75) / 0.25)

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Shape {
                    width: pageItem.width
                    height: pageItem.height

                    ShapePath {
                        fillColor: "#ffffff"
                        strokeColor: "transparent"

                        PathSvg {
                            path: {
                                const w = pageItem.width;
                                const h = pageItem.height;
                                const c = pageItem.cut;
                                return "M " + c + " 0 L " + (w - c) + " 0 L " + w + " " + c
                                     + " L " + w + " " + (h - c) + " L " + (w - c) + " " + h
                                     + " L " + c + " " + h + " L 0 " + (h - c) + " L 0 " + c + " Z";
                            }
                        }
                    }
                }
            }

            Image {
                anchors.fill: parent
                source: "file://" + path
                asynchronous: false
                cache: true
                smooth: true
            }
        }
    }
}
