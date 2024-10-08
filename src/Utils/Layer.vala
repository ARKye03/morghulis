public interface LayerWindow : Gtk.Window {
    public abstract void init_layer_properties();
    public abstract void present_layer();
}