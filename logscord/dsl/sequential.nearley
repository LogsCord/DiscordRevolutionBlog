On touche plus, sans ambiguité, propre :

@{%
const moo = require("moo");

const lexer = moo.compile({
  ws:        { match: /[ \t\n\r]+/, lineBreaks: true },

  lbrace:    "{",
  rbrace:    "}",
  lparen:    "(",
  rparen:    ")",
  comma:     ",",
  arrow:     "=>",
  dot:       ".",

  eq:        "==",
  ne:        "!=",
  ge:        ">=",
  le:        "<=",
  gt:        ">",
  lt:        "<",
  assign:    "=",           

  kw_monoid: "monoid",
  kw_reduce: "reduce",
  kw_per:    "per",
  kw_user:   "user",
  kw_using:  "using",
  kw_on:     "on",
  kw_when:   "when",
  kw_yield:  "yield",
  kw_metric: "metric",
  kw_from:   "from",
  kw_aggregate: "aggregate",
  kw_group:  "group",
  kw_by:     "by",
  kw_range:  "range",
  kw_emits:  "emits",

  duration:  /[0-9]+(?:h|m|s)/,
  number:    /[0-9]+(?:\.[0-9]+)?/,
  sign:      /[+-]/,
  string:    /"(?:[^"\\]|\\.)*"/,
  ident:     /[a-zA-Z_][a-zA-Z0-9_]*/,
});

function stripQuotes(s) {
  return s.slice(1, -1);
}
%}

@lexer lexer

# =====================================================
# ENTRY
# =====================================================

Main ->
  __ StatementList __
  {% d => ({ type:"program", statements:d[1] }) %}

StatementList ->
  Statement (__ Statement):*
  {% d => [ d[0][0], ...d[1].map(x => x[1][0]) ] %}

Statement ->
    MonoidDecl
  | ReduceDecl
  | MetricDecl

# =====================================================
# MONOID
# =====================================================

MonoidDecl ->
  %kw_monoid _ %kw_per _ %kw_user _ Identifier _ MonoidBlock
  {% ([,,,,,, name,, events]) => ({
    type:"monoid",
    name:name.name,
    events
  }) %}

MonoidBlock ->
  %lbrace __ MonoidEvents __ %rbrace {% d => d[2] %}
| %lbrace __ %rbrace                 {% () => [] %}

MonoidEvents ->
  MonoidEvent (__ MonoidEvent):*
  {% d => [ d[0], ...d[1].map(x => x[1]) ] %}

MonoidEvent ->
  %kw_emits _ Identifier _ %kw_when _ Expr
  {% ([,, sig,, , , cond]) => ({
    type:"emit",
    signal:sig.name,
    condition:cond
  }) %}

# =====================================================
# REDUCE
# =====================================================

ReduceDecl ->
  %kw_reduce _ %kw_per _ %kw_user _ Identifier _
  %kw_using _ Identifier _ ReduceBlock
  {% ([,,,,,, name,, , , source,, body]) => ({
    type:"reduce",
    name:name.name,
    source:source.name,
    body
  }) %}

ReduceBlock ->
  %lbrace __ ReduceBody __ %rbrace {% d => d[2] %}
| %lbrace __ %rbrace               {% () => [] %}

ReduceBody ->
  ReduceStmt (__ ReduceStmt):*
  {% d => [ d[0], ...d[1].map(x => x[1]) ] %}

ReduceStmt ->
    Assignment
  | OnBlock
  | YieldStmt

Assignment ->
  Identifier _ %assign _ Value
  {% ([id,, , , val]) => ({
    type:"assign",
    name:id.name,
    value:val
  }) %}

# =====================================================
# ON / WHEN
# =====================================================

OnBlock ->
  %kw_on _ SourceSignal _ %lbrace __ WhenCases __ %rbrace
  {% ([,, sig,, , cases]) => ({
    type:"on",
    signal:sig,
    cases
  }) %}

SourceSignal ->
  Identifier %dot Identifier
  {% ([s,, ev]) => ({ source:s.name, signal:ev.name }) %}

WhenCases ->
  WhenCase (__ WhenCase):*
  {% d => [ d[0], ...d[1].map(x => x[1]) ] %}

WhenCase ->
  %kw_when _ Expr _ %arrow _ Actions
  {% ([,, cond,, , , acts]) => ({
    condition:cond,
    actions:acts
  }) %}

# =====================================================
# ACTIONS
# =====================================================

Actions ->
  %lbrace __ ActionList __ %rbrace {% d => d[2] %}
| %lbrace __ %rbrace               {% () => [] %}

ActionList ->
  Action (__ %comma __ Action):*
  {% d => [ d[0], ...d[1].map(x => x[3]) ] %}

Action ->
  Identifier __ %assign __ Value
  {% ([id,, , , val]) => ({
    type:"action",
    name:id.name,
    value:val
  }) %}

# =====================================================
# VALUES / EXPRESSIONS
# =====================================================

Value ->
    Literal
  | Identifier

Literal ->
    SignedNumber
  | Number
  | Duration
  | String

SignedNumber ->
  %sign Number
  {% ([s, n]) => ({
    type:"number",
    value: s.value === "+" ? n.value : -n.value
  }) %}

Number ->
  %number {% d => ({ type:"number", value:Number(d[0].value) }) %}

Duration ->
  %duration {% d => ({ type:"duration", raw:d[0].value }) %}

String ->
  %string {% d => ({ type:"string", value:stripQuotes(d[0].value) }) %}

Expr ->
    SimpleExpr
  | SimpleExpr __ CompOp __ SimpleExpr
    {% ([l,,op,,r]) => ({
      type:"binary",
      op,
      left:l,
      right:r
    }) %}

SimpleExpr ->
    Field
  | Literal
  | Identifier

Field ->
  Identifier %dot Identifier
  {% ([s,, f]) => ({ type:"field", source:s.name, field:f.name }) %}

CompOp ->
    %eq {% () => "==" %}
  | %ne {% () => "!=" %}
  | %ge {% () => ">=" %}
  | %le {% () => "<=" %}
  | %gt {% () => ">"  %}
  | %lt {% () => "<"  %}

Identifier ->
  %ident {% d => ({ type:"identifier", name:d[0].value }) %}

# =====================================================
# YIELD
# =====================================================

YieldStmt ->
  %kw_yield _ Identifier
  {% ([,, id]) => ({ type:"yield", name:id.name }) %}

# =====================================================
# METRIC
# =====================================================

MetricDecl ->
  %kw_metric _ Identifier _ MetricBlock
  {% ([,, name,, body]) => ({
    type:"metric",
    name:name.name,
    body
  }) %}

MetricBlock ->
  %lbrace __ MetricBody __ %rbrace {% d => d[2] %}

MetricBody ->
  MetricStmt (__ MetricStmt):*
  {% d => [ d[0], ...d[1].map(x => x[1]) ] %}

MetricStmt ->
    MetricFrom
  | MetricUsing
  | MetricAggregate
  | MetricGroup
  | MetricRange

MetricFrom ->
  %kw_from _ Identifier
  {% ([,, src]) => ({ type:"from", source:src.name }) %}

MetricUsing ->
  %kw_using _ Identifier
  {% ([,, id]) => ({ type:"using", name:id.name }) %}

MetricAggregate ->
  %kw_aggregate _ Identifier %lparen Identifier %rparen
  {% ([,, fn,, arg]) => ({
    type:"aggregate",
    function:fn.name,
    argument:arg.name
  }) %}

MetricGroup ->
  %kw_group _ %kw_by _ TimeBucket
  {% ([,,, , tb]) => ({ type:"group_by", bucket:tb }) %}

TimeBucket ->
  Identifier %lparen TimeValue %rparen
  {% ([id,, v]) => ({
    type:"time_bucket",
    name:id.name,
    value:v
  }) %}

TimeValue ->
    Number
  | Duration

MetricRange ->
  %kw_range _ RangeValue
  {% ([,, v]) => ({ type:"range", value:v }) %}

RangeValue ->
    Number
  | Duration

# =====================================================
# WHITESPACE
# =====================================================

_  -> %ws:+
__ -> %ws:*
