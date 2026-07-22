// Sandboxed image decoding via glycin: raw encoded bytes -> Gdk.Texture.
public class ImageLoader : Object {
    // Decode `bytes` to a texture whose longest edge is <= max_edge (aspect
    // preserved). Fail-soft: returns null on any decode error.
    public static async Gdk.Texture? from_bytes(GLib.Bytes bytes, int max_edge,
                                                GLib.Cancellable? cancellable = null) {
        try {
            var loader = new Gly.Loader.for_bytes(bytes);
            var image = yield loader.load_async(cancellable);

            var req = new Gly.FrameRequest();
            uint w = image.get_width();
            uint h = image.get_height();
            if (w > 0 && h > 0 && (w > max_edge || h > max_edge)) {
                double scale = (double) max_edge / (double) uint.max(w, h);
                req.set_scale((uint) (w * scale), (uint) (h * scale));
            }

            var frame = yield image.get_specific_frame_async(req, cancellable);
            return GlyGtk4.frame_get_texture(frame);
        } catch (Error e) {
            warning("ImageLoader: decode failed: %s", e.message);
            return null;
        }
    }
}
