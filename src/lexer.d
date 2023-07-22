module lexer;

import source.lexbase;
import source.context;
import source.location;
import source.packedfloat;

enum TokenType {
    Invalid,
    Begin,
    End,
    Comment,
    FloatLiteral,
    Identifier,
    For,
    OpenBrace, // {
    CloseBrace, // }
    RightArrow, // ->
    LeftArrow, // <-
    QuestionMark, // ?
}

struct Token {
private:
    import util.bitfields;
    enum TypeSize = EnumSize!TokenType;
    enum ExtraBits = 8 * uint.sizeof - TypeSize;

    import std.bitmanip;
    mixin(bitfields!(
        // sdfmt off
        TokenType, "_type", TypeSize,
        uint, "_extra", ExtraBits,
        // sdfmt on
    ));

    import source.location;
    Location _location;

    import source.name;
    union {
        import source.name;
        Name _name;

        uint _base;
    }

public:
    @property
    TokenType type() const {
        return _type;
    }

    @property
    Location location() const {
        return _location;
    }

    @property
    Name name() const in(type >= TokenType.Identifier) {
        return _name;
    }

    @property
    Name error() const in(type == TokenType.Invalid) {
        return _name;
    }

    import source.packedfloat;
    alias PackedFloat = source.packedfloat.PackedFloat!ExtraBits;

    PackedFloat packedFloat() const in(type == TokenType.FloatLiteral) {
        return PackedFloat.recompose(_base, _extra);
    }

    import source.context;
    string toString(Context context) const {
        return (type >= TokenType.Identifier)
            ? name.toString(context)
            : location.getFullLocation(context).getSlice();
    }

    static getError(Location location, Name message) {
        Token t;
        t._type = TokenType.Invalid;
        t._name = message;
        t._location = location;

        return t;
    }

    static getBegin(Location location, Name name) {
        Token t;
        t._type = TokenType.Begin;
        t._name = name;
        t._location = location;

        return t;
    }

    static getEnd(Location location) {
        Token t;
        t._type = TokenType.End;
        t._name = BuiltinName!"\0";
        t._location = location;

        return t;
    }

    static getComment(string s)(Location location) {
        Token t;
        t._type = TokenType.Comment;
        t._name = BuiltinName!s;
        t._location = location;

        return t;
    }

    static getFloatLiteral(Location location, PackedFloat value) {
        Token t;
        t._type = TokenType.FloatLiteral;
        t._location = location;

        t._base = value.base;
        t._extra = value.extra;

        return t;
    }

    static getIdentifier(Location location, Name name) {
        Token t;
        t._type = TokenType.Identifier;
        t._name = name;
        t._location = location;

        return t;
    }

    static getKeyword(string kw)(Location location, Name name) {
        enum Type = FelixLexer.KeywordMap[kw];

        Token t;
        t._type = Type;
        t._name = name;
        t._location = location;

        return t;
    }

    static getOperator(string op)(Location location, Name name) {
        enum Type = FelixLexer.OperatorMap[op];

        Token t;
        t._type = Type;
        t._name = name;
        t._location = location;

        return t;
    }
}

alias TokenRange = FelixLexer;

struct FelixLexer {
    enum BaseMap = () {
        auto ret = [
            // sdfmt off
            // Comments
            "//" : "?Comment",
            "/*" : "?Comment",

            "0b" : "lexNumeric",
            "0B" : "lexNumeric",
            "0x" : "lexNumeric",
            "0X" : "lexNumeric",
            // sdfmt on
        ];

        return registerNumericPrefixes(ret);
    }();

    enum KeywordMap = getKeywordsMap();
    enum OperatorMap = getOperatorsMap();

    import source.lexbase;
    mixin LexBaseImpl!(Token, BaseMap, KeywordMap, OperatorMap);

    // implementing this to override the implementation from `LexBaseImpl`
    auto lexOperator(string s)() {
        uint l = s.length;
        uint begin = index - l;
        auto loc = base.getWithOffsets(begin, index);
        return
            Token.getOperator!s(loc, context.getName(content[begin .. index]));
    }

    // implementing this to override the implementation from `LexBaseImpl`
    import source.name;
    auto lexKeyword(string s)() {
        enum Type = KeywordMap[s];
        uint l = s.length;
        uint begin = index - l;

        auto location = base.getWithOffsets(begin, index);

        if (popIdentifierWithPrefix!s() == 0) {
            return Token.getKeyword!s(location,
                                      context.getName(content[begin .. index]));
        }

        // This is an identifier that happened to start
        // like a keyword.
        return Token
            .getIdentifier(location, context.getName(content[begin .. index]));
    }

    import source.name;

    Name popSheBang() {
        auto c = frontChar;
        if (c != '#') {
            return BuiltinName!"";
        }

        while (c != '\n') {
            popChar();
            c = frontChar;
        }

        return context.getName(content[0 .. index]);
    }

    import source.lexnumeric;
    mixin LexNumericImpl!(Token, ["": "getIntegerFloatLiteral"]);

    auto getIntegerFloatLiteral(string s)(Location location, ulong value,
                                          bool overflow) {
        if (overflow) {
            return getHexFloatLiteral(location, value, overflow, 0);
        }

        auto pf = Token.PackedFloat.fromInt(context, value);
        return Token.getFloatLiteral(location, pf);
    }
}

auto getOperatorsMap() {
    with (TokenType) return [
        // sdfmt off
        "\0"   : End,
        "{"    : OpenBrace,
        "}"    : CloseBrace,
        "->"   : RightArrow,
        "<-"   : LeftArrow,
        "?"    : QuestionMark,
        // sdfmt on
    ];
}

auto getKeywordsMap() {
    with (TokenType) return [
        // sdfmt off
        "for"              : For,
        // sdfmt on
    ];
}

auto lex(Position base, Context context) {
    auto lexer = FelixLexer();

    lexer.context = context;
    lexer.base = base;
    lexer.previous = base;
    lexer.content = base.getFullPosition(context).getSource().getContent();

    // Pop #!
    auto shebang = lexer.popSheBang();
    auto beginLocation = Location(base, base.getWithOffset(lexer.index));

    lexer.t = Token.getBegin(beginLocation, shebang);

    return lexer;
}

unittest {
    auto context = new Context();

    auto testlexer(string s) {
        auto base = context.registerMixin(Location.init, s ~ '\0');
        return lex(base, context);
    }

    import source.parserutil;

    {
        auto lex = testlexer("");
        lex.match(TokenType.Begin);
        assert(lex.front.type == TokenType.End);
    }

    {
        auto lex = testlexer("a");
        lex.match(TokenType.Begin);

        auto t = lex.front;

        assert(t.type == TokenType.Identifier);
        assert(t.name.toString(context) == "a");
        lex.popFront();

        assert(lex.front.type == TokenType.End);
    }

    {
        auto lex = testlexer("0.1");
        lex.match(TokenType.Begin);
        lex.match(TokenType.FloatLiteral);
        assert(lex.front.type == TokenType.End);
    }

    {
        auto lex = testlexer("1");
        lex.match(TokenType.Begin);
        lex.match(TokenType.FloatLiteral);
        assert(lex.front.type == TokenType.End);
    }

    {
        auto lex = testlexer("->");
        lex.match(TokenType.Begin);
        lex.match(TokenType.RightArrow);
        assert(lex.front.type == TokenType.End);
    }

    {
        auto lex = testlexer("<-");
        lex.match(TokenType.Begin);
        lex.match(TokenType.LeftArrow);
        assert(lex.front.type == TokenType.End);
    }

    {
        auto lex = testlexer("a <- b");
        lex.match(TokenType.Begin);
        lex.match(TokenType.Identifier);
        lex.match(TokenType.LeftArrow);
        lex.match(TokenType.Identifier);
        assert(lex.front.type == TokenType.End);
    }
}
