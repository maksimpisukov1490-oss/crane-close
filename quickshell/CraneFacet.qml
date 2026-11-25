import QtQuick
import QtQuick3D
import QtQuick3D.Helpers

// Одна бумажная грань журавлика: лицевая сторона с куском страницы,
// изнанка чёрная. Точки задаются в локальных координатах грани.
Node {
    id: facet

    property var points: []
    property var uvs: []
    property real shade: 1.0
    property string shotUrl: ""

    readonly property var safePoints: points || []
    readonly property var safeUvs: uvs || []

    readonly property var normal: {
        if (safePoints.length < 3)
            return Qt.vector3d(0, 0, 1);
        const a = safePoints[0], b = safePoints[1], c = safePoints[2];
        const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
        const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
        let nx = uy * vz - uz * vy;
        let ny = uz * vx - ux * vz;
        let nz = ux * vy - uy * vx;
        const l = Math.sqrt(nx * nx + ny * ny + nz * nz) || 1;
        return Qt.vector3d(nx / l, ny / l, nz / l);
    }

    function fanIndexes(count, back) {
        const out = [];
        for (let i = 1; i < count - 1; i++) {
            if (back)
                out.push(0, i + 1, i);
            else
                out.push(0, i, i + 1);
        }
        return out;
    }

    function backPoints() {
        const n = normal;
        return safePoints.map(p => [p[0] - n.x * 0.7, p[1] - n.y * 0.7, p[2] - n.z * 0.7]);
    }

    Model {
        geometry: ProceduralMesh {
            positions: facet.safePoints.map(p => Qt.vector3d(p[0], p[1], p[2]))
            normals: facet.safePoints.map(() => facet.normal)
            uv0s: facet.safeUvs.map(t => Qt.vector2d(t[0], t[1]))
            indexes: facet.fanIndexes(facet.safePoints.length, false)
        }

        materials: PrincipledMaterial {
            lighting: PrincipledMaterial.NoLighting
            baseColor: Qt.rgba(facet.shade, facet.shade, Math.min(1, facet.shade * 1.02), 1)
            baseColorMap: Texture { source: facet.shotUrl }
        }
    }

    Model {
        geometry: ProceduralMesh {
            positions: facet.backPoints().map(p => Qt.vector3d(p[0], p[1], p[2]))
            normals: facet.safePoints.map(() => Qt.vector3d(-facet.normal.x, -facet.normal.y, -facet.normal.z))
            uv0s: facet.safeUvs.map(t => Qt.vector2d(t[0], t[1]))
            indexes: facet.fanIndexes(facet.safePoints.length, true)
        }

        materials: PrincipledMaterial {
            lighting: PrincipledMaterial.NoLighting
            baseColor: "#101014"
        }
    }
}
