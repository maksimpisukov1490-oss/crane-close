import QtQuick
import QtQuick3D
import "facets.js" as Facets

// 3D-журавлик, собранный из плоских бумажных граней.
// На лицевые грани проецируется скриншот окна, изнанка чёрная.
Node {
    id: crane

    property string shotUrl: ""
    // 0 — грани собраны в точку, 1 — журавлик раскрыт
    property real bloom: 1
    // отражённый журавлик — для полёта влево
    property bool mirrored: false
    // взмах крыльев, градусы
    property real flap: 0

    readonly property var defs: mirrored ? Facets.facetsMirror : Facets.facets
    readonly property int count: defs.length

    function centroid(f) {
        let x = 0, y = 0;
        for (let i = 0; i < f.pts.length; i++) {
            x += f.pts[i][0];
            y += f.pts[i][1];
        }
        return [x / f.pts.length, y / f.pts.length, f.z];
    }

    function isWingL(i) {
        return i === 14 || i === 15;
    }
    function isWingR(i) {
        return i === 0 || i === 1 || i === 4 || i === 8 || i === 9 || i === 10;
    }

    function rotatePt(p, axis, deg) {
        const a = deg * Math.PI / 180;
        const c = Math.cos(a);
        const s = Math.sin(a);
        const l = Math.sqrt(axis[0] * axis[0] + axis[1] * axis[1] + axis[2] * axis[2]) || 1;
        const ax = [axis[0] / l, axis[1] / l, axis[2] / l];
        const cr = [ax[1] * p[2] - ax[2] * p[1],
                    ax[2] * p[0] - ax[0] * p[2],
                    ax[0] * p[1] - ax[1] * p[0]];
        const d = ax[0] * p[0] + ax[1] * p[1] + ax[2] * p[2];
        return [p[0] * c + cr[0] * s + ax[0] * d * (1 - c),
                p[1] * c + cr[1] * s + ax[1] * d * (1 - c),
                p[2] * c + cr[2] * s + ax[2] * d * (1 - c)];
    }

    readonly property var wingAxis: mirrored ? [-1, 0.06, 0.25] : [1, 0.06, 0.25]
    readonly property var hingeL: mirrored ? [10, 52, 0] : [-10, 52, 0]
    readonly property var hingeR: mirrored ? [-28, 2, 0] : [28, 2, 0]

    function smooth(x) {
        const t = Math.max(0, Math.min(1, x));
        return t * t * (3 - 2 * t);
    }

    function bloomFor(index) {
        const delay = (index % 7) * 0.035;
        const p = smooth((bloom - delay) / (1 - delay));
        return p;
    }

    function easeOutBack(v) {
        const c1 = 1.70158;
        const c3 = c1 + 1;
        const x = Math.max(0, Math.min(1, v));
        return 1 + c3 * Math.pow(x - 1, 3) + c1 * Math.pow(x - 1, 2);
    }

    Repeater3D {
        model: crane.count

        Node {
            id: facetNode

            required property int index

            readonly property var f: crane.defs[index]
            readonly property var c: crane.centroid(f)
            readonly property real p: crane.bloomFor(index)

            readonly property bool wl: crane.isWingL(index)
            readonly property bool wr: crane.isWingR(index)
            readonly property real ang: (wl ? 1 : (wr ? -1 : 0)) * crane.flap
            readonly property var hinge: wl ? crane.hingeL : (wr ? crane.hingeR : [0, 0, 0])
            readonly property real baseX: c[0] * p
            readonly property real baseY: c[1] * p
            readonly property real baseZ: c[2] * p + Math.sin(Math.PI * p) * (26 + (index % 4) * 9)

            position: {
                if (ang === 0)
                    return Qt.vector3d(baseX, baseY, baseZ);
                const rel = [baseX - hinge[0], baseY - hinge[1], baseZ - hinge[2]];
                const r = crane.rotatePt(rel, crane.wingAxis, ang);
                return Qt.vector3d(hinge[0] + r[0], hinge[1] + r[1], hinge[2] + r[2]);
            }
            readonly property real sc: 0.10 + 0.90 * crane.easeOutBack(Math.min(1, p * 1.1))
            scale: Qt.vector3d(sc, sc, sc)
            rotation: ang !== 0
                ? Quaternion.fromAxisAndAngle(crane.wingAxis[0], crane.wingAxis[1], crane.wingAxis[2], ang)
                : Quaternion.fromEulerAngles((1 - p) * 8 * ((index % 3) - 1),
                                             crane.mirrored ? -(1 - p) * 10 * ((index % 2) ? 1 : -1) : (1 - p) * 10 * ((index % 2) ? 1 : -1),
                                             crane.mirrored ? -(1 - p) * 24 * ((index % 2) ? 1 : -1) : (1 - p) * 24 * ((index % 2) ? 1 : -1))

            CraneFacet {
                points: facetNode.f.pts.map(pt => [pt[0] - facetNode.c[0],
                                                   pt[1] - facetNode.c[1],
                                                   facetNode.f.z - facetNode.c[2]])
                uvs: facetNode.f.uvs
                shade: facetNode.f.shade
                shotUrl: crane.shotUrl
            }
        }
    }
}
