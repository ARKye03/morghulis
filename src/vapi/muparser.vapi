[CCode(cheader_filename = "muParserDLL.h")]
namespace MuParser {
[CCode(cname = "muParserHandle_t", has_type_id = false)]
[SimpleType]
public struct Handle {
}

[CCode(cname = "muFloat_t")]
public struct Float : double {
}

[CCode(cname = "muChar_t")]
public struct Char : char {
}

[CCode(cname = "muBool_t")]
public struct Bool : int {
}

// Parser type constants
[CCode(cname = "muBASETYPE_INT")]
public const int BASETYPE_INT;

[CCode(cname = "muBASETYPE_FLOAT")]
public const int BASETYPE_FLOAT;

// Core functions
[CCode(cname = "mupCreate")]
public Handle create(int base_type = 0);

[CCode(cname = "mupRelease")]
public void release(Handle parser);

[CCode(cname = "mupSetExpr")]
public void set_expr(Handle parser, string expr);

[CCode(cname = "mupGetExpr")]
public unowned string get_expr(Handle parser);

[CCode(cname = "mupEval")]
public double eval(Handle parser);

[CCode(cname = "mupGetVersion")]
public unowned string get_version(Handle parser);

// Variable management
[CCode(cname = "mupDefineVar")]
public void define_var(Handle parser, string name, out double var);

[CCode(cname = "mupDefineConst")]
public void define_const(Handle parser, string name, double value);

// Locale settings
[CCode(cname = "mupSetDecSep")]
public void set_decimal_separator(Handle parser, char sep);

[CCode(cname = "mupSetThousandsSep")]
public void set_thousands_separator(Handle parser, char sep);

[CCode(cname = "mupSetArgSep")]
public void set_argument_separator(Handle parser, char sep);

// Error handling
[CCode(cname = "mupError")]
public bool has_error(Handle parser);

[CCode(cname = "mupGetErrorMsg")]
public unowned string get_error_msg(Handle parser);

[CCode(cname = "mupGetErrorToken")]
public unowned string get_error_token(Handle parser);

[CCode(cname = "mupGetErrorPos")]
public int get_error_pos(Handle parser);
}
