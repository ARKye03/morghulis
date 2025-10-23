// Interface for commands that can handle input from the entry
public interface ICommand : Object {
    // Icon name for this command when it's manually invoked
    public abstract string icon_name { get; }

    // Called when the entry text changes and this command is active
    public abstract void handle_input(string input);

    // Called when the command becomes active
    public virtual void on_activate() {
    }

    // Called when the command becomes inactive
    public virtual void on_deactivate() {
    }

    // Called when Enter is pressed while this command is active
    public virtual void on_enter() {
    }
}
