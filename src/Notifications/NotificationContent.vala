[GtkTemplate(ui = "/com/github/ARKye03/morghulis/ui/NotificationContent.ui")]
public class NotificationContent : Gtk.Box {
    public AstalNotifd.Notification notification { get; set; }

    [GtkChild]
    public unowned Gtk.Box actions_box;

    [GtkChild]
    public unowned Gtk.Label label_body;

    public NotificationContent(AstalNotifd.Notification notification) {
        Object(
            notification: notification
        );
        setup_actions();
        setup_urgency();
        setup_body();
    }

    [GtkCallback]
    public string current_time(int64 t) {
        DateTime dt = new DateTime.from_unix_local(t);

        return dt.format("%H:%M");
    }

    [GtkCallback]
    public void dismiss_notif() {
        this.notification.dismiss();
    }

    private void setup_urgency() {
        if (notification.urgency == AstalNotifd.Urgency.CRITICAL) {
            this.add_css_class("critical");
        } else if (notification.urgency == AstalNotifd.Urgency.LOW) {
            this.add_css_class("low");
        } else {
            this.add_css_class("normal");
        }
    }

    private void setup_actions() {
        notification.actions.@foreach(a => {
            Gtk.Button action = new Gtk.Button.with_label(a.label);
            action.clicked.connect(() => this.notification.invoke(a.id));
            this.actions_box.append(action);
        });
    }

    private void setup_body() {
        if (notification == null) {
            return;
        }

        string body_text = notification.body ?? "";
        if (body_text == "") {
            label_body.hide();
            return;
        }
        label_body.show();

        CMark.Node root = CMark.parse_document(body_text, body_text.length, CMark.Option.DEFAULT);
        if (root == null) {
            label_body.set_text(body_text);
            return;
        }

        StringBuilder sb = new StringBuilder();
        var iter = new CMark.Iter(root);
        CMark.EventType ev;
        int[] list_counters = {};

        while ((ev = iter.next()) != CMark.EventType.DONE) {
            unowned CMark.Node node = iter.get_node();
            bool entering = (ev == CMark.EventType.ENTER);

            switch (node.get_type()) {
                case CMark.NodeType.TEXT:
                    sb.append(Markup.escape_text(node.get_literal() ?? ""));
                break;

                case CMark.NodeType.SOFTBREAK:
                    sb.append(" ");
                break;

                case CMark.NodeType.LINEBREAK:
                    sb.append("\n");
                break;

                case CMark.NodeType.PARAGRAPH:
                    if (!entering) {
                        unowned CMark.Node? next = node.next();
                        if (next != null) {
                            sb.append("\n");
                        }
                    }
                break;

                case CMark.NodeType.HEADING:
                    if (entering) {
                        sb.append("<b>");
                    } else {
                        sb.append("</b>");
                        unowned CMark.Node? next = node.next();
                        if (next != null) {
                            sb.append("\n");
                        }
                    }
                break;

                case CMark.NodeType.STRONG:
                    if (entering) {
                        sb.append("<b>");
                    } else {
                        sb.append("</b>");
                    }
                break;

                case CMark.NodeType.EMPH:
                    if (entering) {
                        sb.append("<i>");
                    } else {
                        sb.append("</i>");
                    }
                break;

                case CMark.NodeType.CODE:
                    sb.append("<tt>");
                    sb.append(Markup.escape_text(node.get_literal() ?? ""));
                    sb.append("</tt>");
                break;

                case CMark.NodeType.CODE_BLOCK:
                    sb.append("<tt>");
                    sb.append(Markup.escape_text(node.get_literal() ?? ""));
                    sb.append("</tt>\n");
                break;

                case CMark.NodeType.LINK:
                    if (entering) {
                        sb.append("<a href=\"");
                        sb.append(Markup.escape_text(node.get_url() ?? ""));
                        sb.append("\">");
                    } else {
                        sb.append("</a>");
                    }
                break;

                case CMark.NodeType.LIST:
                    if (entering) {
                        list_counters += node.get_list_start();
                    } else {
                        if (list_counters.length > 0) {
                            list_counters = list_counters[0 : list_counters.length - 1];
                        }
                        unowned CMark.Node? next = node.next();
                        if (next != null) {
                            sb.append("\n");
                        }
                    }
                break;

                case CMark.NodeType.ITEM:
                    if (entering) {
                        unowned CMark.Node? parent = node.parent();
                        if (parent != null && parent.get_list_type() == CMark.ListType.ORDERED_LIST) {
                            int count = list_counters[list_counters.length - 1];
                            sb.append(@" $(count). ");
                            list_counters[list_counters.length - 1] = count + 1;
                        } else {
                            sb.append(" • ");
                        }
                    } else {
                        unowned CMark.Node? next = node.next();
                        if (next != null) {
                            sb.append("\n");
                        }
                    }
                break;

                case CMark.NodeType.THEMATIC_BREAK:
                    sb.append("────────────────────\n");
                break;

                case CMark.NodeType.BLOCK_QUOTE:
                    if (entering) {
                        sb.append("<i>〉");
                    } else {
                        sb.append("</i>\n");
                    }
                break;

                default:
                break;
            }
        }

        label_body.set_markup(sb.str.strip());
    }
}
