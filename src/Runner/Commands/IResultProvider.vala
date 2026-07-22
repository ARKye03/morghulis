// A command whose view is a navigable list of results, driven by the arrow keys
// while the entry keeps text focus. activate_selected returns whether to close.
public interface IResultProvider : ICommand {
    public abstract void select_next();
    public abstract void select_prev();
    public abstract bool activate_selected();
}
