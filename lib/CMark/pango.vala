namespace CMark {
public static string parse_to_pango(string? markdown) {
    if (markdown == null || markdown == "") {
        return "";
    }

    CMark.Node root = CMark.parse_document(markdown, markdown.length, CMark.Option.DEFAULT);
    if (root == null) {
        return Markup.escape_text(markdown);
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

    return sb.str.strip();
}
}
