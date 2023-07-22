module ast;

public import source.location;
import source.context;
import source.name;

class Node {
    Location location;

    this(Location location) {
        this.location = location;
    }

    invariant() {
        assert(location != Location.init, "node location must never be init");
    }

final:
    import source.context;
    auto getFullLocation(Context c) const {
        return location.getFullLocation(c);
    }
}

abstract class AstExpression : Node {
    this(Location location) {
        super(location);
    }

    string toString(const Context) const {
        assert(0, "toString not implement for " ~ typeid(this).toString());
    }
}

enum AstBinaryOp {
    Assign,
}

class AstBinaryExpression : AstExpression {
    AstBinaryOp op;

    AstExpression lhs;
    AstExpression rhs;

    this(Location location, AstBinaryOp op, AstExpression lhs,
         AstExpression rhs) {
        super(location);

        this.op = op;
        this.lhs = lhs;
        this.rhs = rhs;
    }

    override string toString(const Context c) const {
        import std.conv;
        return lhs.toString(c) ~ " " ~ to!string(op) ~ " " ~ rhs.toString(c);
    }
}

final class Module : Node {
    Name name;
    Name[] packages;

    AstExpression[] toplevelExprs;

    this(Location location, Name name, Name[] packages,
         AstExpression[] toplevelExprs) {
        super(location);

        this.name = name;
        this.packages = packages;
        this.toplevelExprs = toplevelExprs;
    }
}

abstract class Identifier : AstExpression {
    this(Location location) {
        super(location);
    }
}

final class BasicIdentifier : Identifier {
    Name name;

    this(Location location, Name name) {
        super(location);

        this.name = name;
    }

    override string toString(const Context c) const {
        return name.toString(c);
    }
}

class FloatLiteral : AstExpression {
    double value;

    this(Location location, double value) {
        super(location);

        this.value = value;
    }

    override string toString(const Context) const {
        import std.conv;
        return to!string(value);
    }
}
