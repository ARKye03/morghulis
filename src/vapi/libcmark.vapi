/* cmark.h - CommonMark parsing, manipulating, and rendering */
[CCode(cheader_filename = "cmark.h", cprefix = "CMARK_", lower_case_cprefix = "cmark_")]
namespace CMark {
[CCode(cname = "int", cprefix = "CMARK_OPT_", has_type_id = false)]
[Flags]
public enum Option {
    DEFAULT,
    SOURCEPOS,
    HARDBREAKS,
    SAFE,
    UNSAFE,
    NOBREAKS,
    NORMALIZE,
    VALIDATE_UTF8,
    SMART
}

[CCode(cname = "cmark_node_type", cprefix = "CMARK_NODE_", has_type_id = false)]
public enum NodeType {
    NONE,
    DOCUMENT,
    BLOCK_QUOTE,
    LIST,
    ITEM,
    CODE_BLOCK,
    HTML_BLOCK,
    CUSTOM_BLOCK,
    PARAGRAPH,
    HEADING,
    THEMATIC_BREAK,
    FIRST_BLOCK,
    LAST_BLOCK,
    TEXT,
    SOFTBREAK,
    LINEBREAK,
    CODE,
    HTML_INLINE,
    CUSTOM_INLINE,
    EMPH,
    STRONG,
    LINK,
    IMAGE,
    FIRST_INLINE,
    LAST_INLINE;

    [CCode(cname = "cmark_node_get_type_string")]
    public unowned string to_string(Node node);
}

[CCode(cname = "cmark_list_type", cprefix = "CMARK_", has_type_id = false)]
public enum ListType {
    NO_LIST,
    BULLET_LIST,
    ORDERED_LIST
}

[CCode(cname = "cmark_delim_type", cprefix = "CMARK_", has_type_id = false)]
public enum DelimType {
    NO_DELIM,
    PERIOD_DELIM,
    PAREN_DELIM
}

[CCode(cname = "cmark_event_type", cprefix = "CMARK_EVENT_", has_type_id = false)]
public enum EventType {
    NONE,
    DONE,
    ENTER,
    EXIT
}

[SimpleType]
[CCode(cname = "cmark_mem", has_type_id = false)]
public struct Mem {
    public void* calloc;
    public void* realloc;
    public void* free;
}

[CCode(cname = "cmark_get_default_mem_allocator")]
public static unowned Mem get_default_mem_allocator();

[Compact]
[CCode(cname = "cmark_node", free_function = "cmark_node_free", has_type_id = false)]
public class Node {
    [CCode(cname = "cmark_node_new")]
    public Node(NodeType type);

    [CCode(cname = "cmark_node_new_with_mem")]
    public Node.with_mem(NodeType type, Mem mem);

    [CCode(cname = "cmark_node_next")]
    public unowned Node? next();

    [CCode(cname = "cmark_node_previous")]
    public unowned Node? previous();

    [CCode(cname = "cmark_node_parent")]
    public unowned Node? parent();

    [CCode(cname = "cmark_node_first_child")]
    public unowned Node? first_child();

    [CCode(cname = "cmark_node_last_child")]
    public unowned Node? last_child();

    [CCode(cname = "cmark_node_get_user_data")]
    public void* get_user_data();

    [CCode(cname = "cmark_node_set_user_data")]
    public bool set_user_data(void* user_data);

    [CCode(cname = "cmark_node_get_type")]
    public NodeType get_type();

    [CCode(cname = "cmark_node_get_literal")]
    public unowned string? get_literal();

    [CCode(cname = "cmark_node_set_literal")]
    public bool set_literal(string content);

    [CCode(cname = "cmark_node_get_heading_level")]
    public int get_heading_level();

    [CCode(cname = "cmark_node_set_heading_level")]
    public bool set_heading_level(int level);

    [CCode(cname = "cmark_node_get_list_type")]
    public ListType get_list_type();

    [CCode(cname = "cmark_node_set_list_type")]
    public bool set_list_type(ListType type);

    [CCode(cname = "cmark_node_get_list_delim")]
    public DelimType get_list_delim();

    [CCode(cname = "cmark_node_set_list_delim")]
    public bool set_list_delim(DelimType delim);

    [CCode(cname = "cmark_node_get_list_start")]
    public int get_list_start();

    [CCode(cname = "cmark_node_set_list_start")]
    public bool set_list_start(int start);

    [CCode(cname = "cmark_node_get_list_tight")]
    public bool get_list_tight();

    [CCode(cname = "cmark_node_set_list_tight")]
    public bool set_list_tight(bool tight);

    [CCode(cname = "cmark_node_get_fence_info")]
    public unowned string? get_fence_info();

    [CCode(cname = "cmark_node_set_fence_info")]
    public bool set_fence_info(string info);

    [CCode(cname = "cmark_node_get_url")]
    public unowned string? get_url();

    [CCode(cname = "cmark_node_set_url")]
    public bool set_url(string url);

    [CCode(cname = "cmark_node_get_title")]
    public unowned string? get_title();

    [CCode(cname = "cmark_node_set_title")]
    public bool set_title(string title);

    [CCode(cname = "cmark_node_get_on_enter")]
    public unowned string? get_on_enter();

    [CCode(cname = "cmark_node_set_on_enter")]
    public bool set_on_enter(string on_enter);

    [CCode(cname = "cmark_node_get_on_exit")]
    public unowned string? get_on_exit();

    [CCode(cname = "cmark_node_set_on_exit")]
    public bool set_on_exit(string on_exit);

    [CCode(cname = "cmark_node_get_start_line")]
    public int get_start_line();

    [CCode(cname = "cmark_node_get_start_column")]
    public int get_start_column();

    [CCode(cname = "cmark_node_get_end_line")]
    public int get_end_line();

    [CCode(cname = "cmark_node_get_end_column")]
    public int get_end_column();

    [CCode(cname = "cmark_node_unlink")]
    public void unlink();

    [CCode(cname = "cmark_node_insert_before")]
    public bool insert_before(Node sibling);

    [CCode(cname = "cmark_node_insert_after")]
    public bool insert_after(Node sibling);

    [CCode(cname = "cmark_node_replace")]
    public bool replace(Node newnode);

    [CCode(cname = "cmark_node_prepend_child")]
    public bool prepend_child(Node child);

    [CCode(cname = "cmark_node_append_child")]
    public bool append_child(Node child);

    [CCode(cname = "cmark_consolidate_text_nodes")]
    public void consolidate_text_nodes();
}

[Compact]
[CCode(cname = "cmark_parser", free_function = "cmark_parser_free", has_type_id = false)]
public class Parser {
    [CCode(cname = "cmark_parser_new")]
    public Parser(int options);

    [CCode(cname = "cmark_parser_new_with_mem")]
    public Parser.with_mem(int options, Mem mem);

    [CCode(cname = "cmark_parser_new_with_mem_into_root")]
    public Parser.with_mem_into_root(int options, Mem mem, Node root);

    [CCode(cname = "cmark_parser_feed")]
    public void feed(string buffer, size_t len);

    [CCode(cname = "cmark_parser_finish")]
    public Node finish();
}

[Compact]
[CCode(cname = "cmark_iter", free_function = "cmark_iter_free", has_type_id = false)]
public class Iter {
    [CCode(cname = "cmark_iter_new")]
    public Iter(Node root);

    [CCode(cname = "cmark_iter_next")]
    public EventType next();

    [CCode(cname = "cmark_iter_get_node")]
    public unowned Node get_node();

    [CCode(cname = "cmark_iter_get_event_type")]
    public EventType get_event_type();

    [CCode(cname = "cmark_iter_get_root")]
    public unowned Node get_root();

    [CCode(cname = "cmark_iter_reset")]
    public void reset(Node current, EventType event_type);
}

[CCode(cname = "cmark_markdown_to_html")]
public static string markdown_to_html(string text, size_t len, int options);

[CCode(cname = "cmark_parse_document")]
public static Node parse_document(string buffer, size_t len, int options);

[CCode(cname = "cmark_parse_file")]
public static Node parse_file(GLib.FileStream f, int options);

[CCode(cname = "cmark_render_xml")]
public static string render_xml(Node root, int options);

[CCode(cname = "cmark_render_html")]
public static string render_html(Node root, int options);

[CCode(cname = "cmark_render_man")]
public static string render_man(Node root, int options, int width);

[CCode(cname = "cmark_render_commonmark")]
public static string render_commonmark(Node root, int options, int width);

[CCode(cname = "cmark_render_latex")]
public static string render_latex(Node root, int options, int width);

[CCode(cname = "cmark_version")]
public static int version();

[CCode(cname = "cmark_version_string")]
public static unowned string version_string();
}
