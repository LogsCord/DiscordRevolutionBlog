@{%
const moo = require("moo");

const lexer = moo.compile({
  ws:         { match: /[ \t\n\r]+/, lineBreaks: true },
  lbrace:     "{",
  rbrace:     "}",
  lparen:     "(",
  rparen:     ")",
  lbracket:   "[",
  rbracket:   "]",
  comma:      ",",
  dot:        ".",

  // operators
  op_in:      "in",
  op_not:     "not",
  op_and:     "and",
  op_or:      "or",
  eq:         "==",
  ne:         "!=",
  ge:         ">=",
  le:         "<=",
  gt:         ">",
  lt:         "<",

  // projections: [*], [&]
  star:       "*",
  amp:        "&",

  number:     /[0-9]+/,
  string:     /"(?:[^"\\]|\\.)*"/,
  identifier: /[a-zA-Z_][a-zA-Z0-9_]*/,
});
%}

@lexer lexer

@{%
const mkBinary = (op, left, right) => ({ type: "binary", op, left, right });
const mkUnary  = (op, value)       => ({ type: "unary", op, value });
const mkCall   = (name, args)      => ({ type: "call", name, args });
const mkIdent  = (name)            => ({ type: "identifier", name });
const mkString = (value)           => ({ type: "string", value });
const mkNumber = (value)           => ({ type: "number", value });
const mkProj   = (source, op)      => ({ type: "projection", op, source });
%}

Main -> OrExpr {% (d) => d[0] %}


# ===================== LOGICAL =====================

OrExpr ->
    AndExpr ( _ "or" _ AndExpr ):* {%
      function(d) {
        let left = d[0];
        d[1].forEach(chunk => {
          left = mkBinary("or", left, chunk[3]);
        });
        return left;
      }
    %}

AndExpr ->
    NotExpr ( _ "and" _ NotExpr ):* {%
      function(d) {
        let left = d[0];
        d[1].forEach(chunk => {
          left = mkBinary("and", left, chunk[3]);
        });
        return left;
      }
    %}

NotExpr ->
    "not" _ NotExpr {% d => mkUnary("not", d[2]) %}
  | CompareExpr      {% id %}


# ===================== COMPARISONS =====================

CompareExpr ->
    Primary  _ "in" _ Set           {% d => mkBinary("in", d[0], d[4]) %}
  | Primary  _ "not" _ "in" _ Set   {% d => mkBinary("not in", d[0], d[5]) %}
  | Primary                         {% id %}


# ===================== PRIMARY + PROJECTIONS =====================

Primary ->
    BasePrimary ProjectionChain:? {%
      function(d) {
        let node = d[0];
        const projs = d[1] || [];
        projs.forEach(p => {
          node = mkProj(node, p);
        });
        return node;
      }
    %}

BasePrimary ->
    FunctionCall {% id %}
  | Identifier   {% id %}
  | String       {% id %}
  | "(" _ OrExpr _ ")" {% d => d[2] %}


# ===================== PROJECTIONS =====================

ProjectionChain ->
    Projection:+  {% d => d[0] %}

Projection ->
    %lbracket %star %rbracket   {% () => "*" %}
    # tu peux ajouter plus tard [%amp] ou [Number]


# ===================== FUNCTION CALL =====================

FunctionCall ->
    Identifier %lparen Identifier %rparen {%
      d => mkCall(d[0].name, [ d[2].name ])
    %}

# ===================== TERMINALS =====================

Identifier -> %identifier {% d => mkIdent(d[0].value) %}

String -> %string {%
  function(d) {
    const raw = d[0].value;
    return mkString(raw.slice(1,-1));
  }
%}

Number -> %number {% d => mkNumber(Number(d[0])) %}

Set ->
    %lbrace _ SetItems:? _ %rbrace
    {% d => ({ type: "set", values: d[2] || [] }) %}

SetItems ->
    String ( _ %comma _ String ):* {%
      function(d) {
        let first = d[0].value;
        let rest  = d[1].map(x => x[3].value);
        return [first, ...rest];
      }
    %}

_ -> %ws:*
