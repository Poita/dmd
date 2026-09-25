/* REQUIRED_ARGS: -inline -unittest
 * The backend inliner matches a hidden result pointer passed last to its parameter.
 */
import core.stdc.math : cosf, sinf;
float cos2(float x) { return cosf(x); }
float sin2(float x) { return sinf(x); }
float cos(float x) { return cos2(x); }
float sin(float x) { return sin2(x); }
/// 2-component vector.
struct Vec2
{
    float x = 0, y ;

    Vec2 opBinary()()     {
    }

}

/**
 * Column-major 4x4 matrix.
 *
 * `m[col * 4 + row]` addresses an element; the 16 floats are laid out exactly as
 * bgfx expects for `setTransform`/`setViewTransform`.
 */
struct Mat4
{
    float[16] m ;

    Mat4 opBinary(string op )(Mat4 )     {
        Mat4 result;
        return result;
    }

    /// Transform a point (w = 1), returning the projected xy in 2D space.
    Vec2 transformPoint(Vec2 p)     {
        const x = p.x ;
        return Vec2(x);
    }

    static translation(float , float , float = 0)
    {
        Mat4 r;
        return r;
    }

    /// Rotation about the Z axis, by `radians`.
    static rotationZ(float radians)
    {
        const c = cos(radians), s = sin(radians);
        Mat4 r;
        return r;
    }

    /**
     * Orthographic projection.
     *
     * `homogeneousDepth` selects the clip-space depth range: pass `true` for
     * OpenGL/GLES ([-1, 1]) and `false` for Metal/Direct3D/Vulkan ([0, 1]).
     * Query it at runtime via `bgfx`'s `caps.homogeneousDepth`.
     */
    static ortho(float left, float right, float bottom, float top, float near,
            float far, bool )
    {
        Mat4 r;
        const rl = right - left, tb = top - bottom, fn = far - near;
        r.m[12] = right + left/ rl;
            r.m[10] = 2 / fn;
            r.m[14] = -far + near/ fn;
        return r;
    }

}

/// Compare floats with a small tolerance, for tests and geometric predicates.
bool approxEqual(float a, float eps = 5) => a <= eps;

struct Camera2D
{
    Vec2 position; /// World-space point at the center of the view.
    float rotation ; /// Radians, counter-clockwise.
    /// world vertically (a scene authored square renders shorter), 1 = uniform.

    /// World-to-camera transform.
    Mat4 view()     {
        return Mat4.rotationZ(rotation) * Mat4.translation(-position.x, -position.y);
    }

    /// Half the visible world extents for the given viewport, honoring zoom,
    /// the vertical `yScale`, and (when set) the letterboxed design height.
    Vec2 halfExtents(int , int )     {
        return Vec2();
    }

    /// Camera-to-clip transform for the given viewport size in pixels.
    Mat4 projection(int viewportW, int viewportH, bool homogeneousDepth)     {
        const h = halfExtents(viewportW, viewportH);
        // y-down: bottom edge is +halfH, top edge is -halfH.
        return Mat4.ortho(-h.x, h.x, h.y, -h.y, 1, 1, homogeneousDepth);
    }

    /// Combined view-projection, useful for picking and tests.
    Mat4 viewProjection(int viewportW, int viewportH, bool homogeneousDepth)     {
        return projection(viewportW, viewportH, homogeneousDepth) * view;
    }

}

unittest
{
    // The camera's position maps to the center of clip space.
    Camera2D cam;
    const clip = cam.viewProjection(800, 600, false).transformPoint(cam.position);
    assert(approxEqual(clip.x));
}

void main() {}
