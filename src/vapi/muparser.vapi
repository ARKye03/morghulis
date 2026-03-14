[CCode(cheader_filename = "muParserDLL.h")]
namespace MuParser {
[CCode(cname = "muParserHandle_t", has_type_id = false)]
[SimpleType]
private struct ParserHandle {
}

[CCode(cname = "muBASETYPE_INT")]
public const int BASETYPE_INT;

[CCode(cname = "muBASETYPE_FLOAT")]
public const int BASETYPE_FLOAT;

[Compact]
[CCode(cname = "muParserHandle_t", free_function = "mupRelease")]
public class Parser {
    [CCode(cname = "mupCreate")]
    public Parser(int base_type = BASETYPE_FLOAT);

    public string expression {
        [CCode(cname = "mupGetExpr")]
        get;
        [CCode(cname = "mupSetExpr")]
        set;
    }

    public string version {
        [CCode(cname = "mupGetVersion")]
        get;
    }

    public bool has_error {
        [CCode(cname = "mupError")]
        get;
    }

    public string error_message {
        [CCode(cname = "mupGetErrorMsg")]
        get;
    }

    public string error_token {
        [CCode(cname = "mupGetErrorToken")]
        get;
    }

    public int error_position {
        [CCode(cname = "mupGetErrorPos")]
        get;
    }

    public int error_code {
        [CCode(cname = "mupGetErrorCode")]
        get;
    }

    public int expression_variable_count {
        [CCode(cname = "mupGetExprVarNum")]
        get;
    }

    public int variable_count {
        [CCode(cname = "mupGetVarNum")]
        get;
    }

    public int constant_count {
        [CCode(cname = "mupGetConstNum")]
        get;
    }

    public char decimal_separator {
        [CCode(cname = "mupSetDecSep")]
        set;
    }

    public char thousands_separator {
        [CCode(cname = "mupSetThousandsSep")]
        set;
    }

    public char argument_separator {
        [CCode(cname = "mupSetArgSep")]
        set;
    }

    [CCode(cname = "mupEval")]
    public double eval();

    [CCode(cname = "mupDefineVar")]
    public void define_variable(string name, out double var);

    [CCode(cname = "mupDefineConst")]
    public void define_constant(string name, double value);

    [CCode(cname = "mupRemoveVar")]
    public void remove_variable(string name);

    [CCode(cname = "mupClearVar")]
    public void clear_variables();

    [CCode(cname = "mupClearConst")]
    public void clear_constants();

    [CCode(cname = "mupResetLocale")]
    public void reset_locale();

    [CCode(cname = "mupErrorReset")]
    public void reset_error();
}
}
