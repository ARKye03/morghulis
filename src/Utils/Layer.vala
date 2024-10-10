public interface ILayerWindow : Gtk.Window {
    public abstract string namespace { get; set; }
    public abstract void init_layer_properties ();
    public abstract void present_layer ();
}