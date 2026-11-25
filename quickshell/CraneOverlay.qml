import QtQuick
import Quickshell
import Quickshell.Wayland
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects

// Один оверлей на монитор: страница складывается в журавлика и улетает.
PanelWindow {
    id: win

    property var req: null
    property int seq: 0
    property bool busy: false
    property bool pending: false
    property real t: 0
    // направление полёта: +1 вправо, -1 влево
    property real flyDir: 1
    // насколько высоко улетает
    property real flyUp: 0.75

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

    readonly property var g: req
    readonly property real winW: g ? g.w : 0
    readonly property real winH: g ? g.h : 0
    readonly property real winX: g ? g.x : 0
    readonly property real winY: g ? g.y : 0
    // центр окна в 3D-координатах камеры (0,0 — центр экрана)
    readonly property real pcx: winX + winW / 2 - width / 2
    readonly property real pcy: height / 2 - (winY + winH / 2)
    readonly property string shotUrl: g ? "file://" + g.path : ""

    readonly property real bloomQ: clamp((t - 0.34) / 0.46)
    readonly property real bloomE: smooth(bloomQ)
    readonly property real flyQ: clamp((t - tFly) / (tEnd - tFly))
    readonly property real flyE: Math.pow(flyQ, 1.18)
    // взмахи крыльями: начинаются, когда журавлик собран
    readonly property real flapAngle: {
        if (t < 0.70)
            return 0;
        const w = Math.min(1, (t - 0.70) / 0.18);
        return Math.sin((t - 0.70) * 11.0) * 24 * w;
    }

    readonly property var flightPos: {
        const e = flyE;
        return Qt.vector3d(pcx + flyDir * e * Math.min(winW * 0.75, 980),
                           pcy + e * flyUp * Math.min(winH * 0.55, 520),
                           e * 330);
    }

    function clamp(v) {
        return Math.max(0, Math.min(1, v));
    }
    function smooth(v) {
        const x = clamp(v);
        return x * x * (3 - 2 * x);
    }

    onSeqChanged: arm()
    onReqChanged: arm()

    function arm() {
        if (!req || !req.path)
            return;
        if (req.monitor && req.monitor !== (screen ? screen.name : ""))
            return;
        pending = true;
        t = 0;
        busy = true;
        checkReady();
    }

    function checkReady() {
        if (!pending)
            return;
        if (probe.status === Image.Ready)
            begin();
        else if (probe.status === Image.Error)
            stopAll();
    }

    function begin() {
        flyDir = (req && req.dir) ? (req.dir < 0 ? -1 : 1) : (Math.random() < 0.5 ? -1 : 1);
        flyUp = 0.55 + Math.random() * 0.35;
        pending = false;
        readyTimer.stop();
        anim.restart();
    }

    function stopAll() {
        pending = false;
        busy = false;
        anim.stop();
        readyTimer.stop();
    }

    Image {
        id: probe
        source: win.shotUrl
        visible: false
        asynchronous: false
        cache: true
        onStatusChanged: win.checkReady()
    }

    Timer {
        id: readyTimer
        interval: 600
        onTriggered: {
            if (win.pending)
                win.begin();
        }
    }

    onPendingChanged: {
        if (pending)
            readyTimer.restart();
        else
            readyTimer.stop();
    }

    SequentialAnimation {
        id: anim

        NumberAnimation {
            target: win
            property: "t"
            from: 0
            to: win.tEnd
            duration: win.tEnd * 1000
            easing.type: Easing.Linear
        }

        onFinished: win.busy = false
    }

    View3D {
        anchors.fill: parent
        visible: win.busy

        environment: SceneEnvironment {
            backgroundMode: SceneEnvironment.Transparent
            clearColor: "transparent"
        }

        PerspectiveCamera {
            position: Qt.vector3d(0, 0, 1200)
            fieldOfView: 2 * Math.atan((win.height / 2) / 1200) * 180 / Math.PI
        }

        Node {
            id: birdRoot

            position: win.flightPos
            eulerRotation: Qt.vector3d(-6 * win.flyE, -win.flyDir * (8 + 16 * win.flyE), -win.flyDir * (8 + 22 * win.flyE))
            visible: win.busy && win.t > 0.28

            Crane3D {
                shotUrl: win.shotUrl
                bloom: win.bloomE
                mirrored: win.flyDir < 0
                flap: win.flapAngle
            }
        }
    }

    // лист со скриншотом: сминается, срезая углы, и уходит в точку
    Item {
        id: page2d

        readonly property real q: win.smooth(win.clamp((win.t - 0.30) / 0.26))
        readonly property real cut: Math.min(width, height) * (0.02 + 0.30 * q)

        x: win.winX
        y: win.winY
        width: win.winW
        height: win.winH
        visible: win.busy && win.t >= 0.0 && win.t < 0.62
        transformOrigin: Item.Center
        scale: 1 - 0.95 * q
        rotation: -9 * q
        opacity: q < 0.75 ? 1 : Math.max(0, 1 - (q - 0.75) / 0.25)

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Shape {
                width: page2d.width
                height: page2d.height

                ShapePath {
                    fillColor: "#ffffff"
                    strokeColor: "transparent"

                    PathSvg {
                        path: {
                            const w = page2d.width;
                            const h = page2d.height;
                            const c = page2d.cut;
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
            source: win.shotUrl
            asynchronous: false
            cache: true
            smooth: true
        }
    }
}