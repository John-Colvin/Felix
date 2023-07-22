module parser;

import lexer;
import ast;
import source.name;
import source.parserutil;

/**
 * Parse a whole module.
 * This is the regular entry point in the parser.
 */
auto parseModule(ref TokenRange trange) {
    Location location = trange.front.location;
    trange.match(TokenType.Begin);

    Name name;
    Name[] packages;

    AstExpression[] toplevelExprs;
    while (trange.front.type != TokenType.End) {
        toplevelExprs ~= trange.parseExpression();
    }

    return new Module(location.spanTo(trange.previous), name, packages,
                      toplevelExprs);
}

AstExpression parseExpression(ref TokenRange trange) {
    auto lhs = trange.parsePrimaryExpression();
    return trange.parseAssignExpression(lhs);
}

AstExpression parsePrimaryExpression(ref TokenRange trange) {
    auto t = trange.front;

    switch (t.type) with (TokenType) {
        case Identifier:
            return trange.parseIdentifier();

        case FloatLiteral:
            return trange.parseFloatLiteral();

        default:
            throw unexpectedTokenError(trange, "an expression");
    }
}

AstExpression parseAssignExpression(ref TokenRange trange, AstExpression lhs) {
    static auto processToken(ref TokenRange trange, AstExpression lhs,
                             AstBinaryOp op) {
        trange.popFront();

        auto rhs = trange.parsePrimaryExpression();
        rhs = trange.parseAssignExpression(rhs);

        auto location = lhs.location.spanTo(trange.previous);
        return new AstBinaryExpression(location, op, lhs, rhs);
    }

    switch (trange.front.type) with (AstBinaryOp) with (TokenType) {
        case LeftArrow:
            return processToken(trange, lhs, Assign);

        default:
            // No assignement.
            return lhs;
    }
}

Identifier parseIdentifier(ref TokenRange trange) {
    auto location = trange.front.location;

    auto name = trange.front.name;
    trange.match(TokenType.Identifier);

    return new BasicIdentifier(location, name);
}

FloatLiteral parseFloatLiteral(ref TokenRange trange) {
    auto t = trange.match(TokenType.FloatLiteral);

    auto litString = t.toString(trange.context);
    assert(litString.length > 1);

    import d.common.builtintype;
    return
        new FloatLiteral(t.location, t.packedFloat.to!double(trange.context));
}

@("Test FloatLiteral parsing")
unittest {
    import source.context;
    auto context = new Context();

    auto makeTestLexer(string s) {
        auto base = context.registerMixin(Location.init, s ~ '\0');
        auto lexer = lex(base, context);

        lexer.match(TokenType.Begin);
        return lexer;
    }

    void floatRoundTrip(const string floatString, const double floatValue) {
        auto lexer = makeTestLexer(floatString);
        const fl = lexer.parseFloatLiteral();

        import std.format : format;
        assert(
            fl.value is floatValue,
            format("%x != %x", *cast(ulong*) &fl.value,
                   *cast(ulong*) &floatValue)
        );
    }

    floatRoundTrip("4.14", 4.14);
    floatRoundTrip("420.0", 420.0);
    floatRoundTrip("4200.0", 4200.0);
    floatRoundTrip("0.222225", 0.222225);
    floatRoundTrip("0x1p-52 ", 0x1p-52);
    floatRoundTrip("0x1.FFFFFFFFFFFFFp1023", 0x1.FFFFFFFFFFFFFp1023);
    floatRoundTrip("1.175494351e-38", 1.175494351e-38);
}

unittest {
    import source.context;
    auto context = new Context();

    auto testParser(string s) {
        auto base = context.registerMixin(Location.init, s ~ '\0');
        auto tr = lex(base, context);
        tr.match(TokenType.Begin);
        auto exp = parseExpression(tr);
        assert(tr.front.type == TokenType.End);
        return exp;
    }

    {
        auto ast = testParser("a <- b");
        import std.stdio;
        writeln(ast.toString(context));
    }

    {
        auto ast = testParser("a <- 3.4");
        import std.stdio;
        writeln(ast.toString(context));
    }
}
