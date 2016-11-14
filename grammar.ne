program     -> _ fn_declaration:* _    {% (d) => d[1] %}
fn_declaration -> _ function _ newline {% (d) => d[1] %}

function    -> "to" __ ident (__ "with" __ signature):? (__ "as" __ typeid):? __ statement {% d => [token.FUNCTION, d[2], (d[3] || [])[3] || [], (d[4]||[])[3] || token.NONE, d[6]] %}
             | comment
signature -> "(" _ (typeid __ ident (_ "," _ typeid __ ident):*):? _ ")" {% d => {
  const isArgs = d[2] instanceof Array

  let args = isArgs ? [
    [d[2][0], d[2][2]]
  ] : []

  if (isArgs) {
    let moreArgs = d[2][3].map(d => [d[3], d[5]])
    args.push(...moreArgs)
  }

  return args
} %}

statements -> (statement (__ | _ ";" _)):* statement {% d => {
  let ss = d[0].map(p => p[0])
  let s = d[1]

  ss.push(s)

  return ss
} %}

statement -> "return" __ expression {% (d) => [token.RETURN, d[2]] %}
           | "if" __ expression __ "then" __ statement {% (d) => [token.IF, d[2], d[6]] %}
           | "if" __ expression __ "then" __ statement __ "else" __ statement {% (d) => [token.IFELSE, d[2], d[6], d[10]] %}
           | "do" __ statements __ "end" {% (d) => [token.DO, d[2]] %}
           | call {% d => d[0] %}
           #| "change" __ ident __ "by" __ expression {% (d) => [token.CHANGE, d[2], d[6]] %}
           | "forever" __ statement {% (d) => [token.FOREVER, d[2]] %}
           | "while" __ expression __ statement {% (d) => [token.WHILE, d[2], d[4]] %}
           | "for each" __ ident __ "in" __ range __ statement {% (d) => [token.FOREACH, d[2], d[6], d[8]] %}
           | _ comment _ {% d => d[1] %}
           | declaration {% d => d[0] %}
           | "set" __ (ident | declaration) __ "to" __ expression {% (d) => [token.SET, d[2], d[6]] %}

declaration -> typeid __ ident {% d => [token.DECLARATION, d[0], d[2]] %}

range -> expression __ "to" __ expression (__ "by" __ expression):?
       | expression __ "through" __ expression (__ "by" __ expression):?

call -> ident "(" expressionlist:? ")" {% (d) => [token.CALL, d[0], d[2]] %}

expressionlist -> expression (_ "," _ expression):* {% d => {
  let r = [
    d[0]
  ]

  let more = d[1].map(d => d[3])
  r.push(...more)

  return r
} %}

expression -> _ EQ _ {% d => d[1] %}

# Brackets
B -> "(" _ AS _ ")"  {% d => d[2] %}
    | type {% d => d[0] %}
    | call {% d => d[0] %}
    | ident {% d => [token.VARIABLE, d[0]] %}

# Indicies
I -> B _ "^" _ I     {% d => [token.POWER, d[0], d[4]] %}
   | B               {% id %}

# Division / Multiplication
DM -> DM _ "*" _ I   {% d => [token.MULTIPLY, d[0], d[4]] %}
    | DM _ "/" _ I   {% d => [token.DIVIDE,   d[0], d[4]] %}
    | I              {% id %}

# Addition / Subtraction
AS -> AS _ "+" _ DM  {% d => [token.ADD,  d[0], d[4]] %}
    | AS _ "-" _ DM  {% d => [token.SUBTRACT, d[0], d[4]] %}
    | DM             {% id %}

# Equality
EQ -> EQ _ "=" _ AS {% d => [Symbol.EQUALS, d[0], d[4]] %}
    | AS               {% id %}

type  -> int    {% d => [token.INTEGER, d[0]] %}
       | float  {% d => [token.FLOAT, d[0]] %}
       | string {% d => [token.STRING, d[0][0]] %}

typeid -> "integer" {% d => token.INTEGER %}
        | "float"   {% d => token.FLOAT %}
        | "string"  {% d => token.STRING %}

int    -> [0-9]:+     {% (d) => parseInt(d[0].join('')) %}
float  -> int "." int {% (d) => parseFloat(d.join('')) %}
string -> dqstring | sqstring

comment -> "/*" .:* "*/" {% d => TOKEN.COMMENT %}

# indentifier
ident  -> [a-zA-Z_]:+ {% (d) => d[0].join('') %}

___     -> _ newline:+ _

newline -> [\n]

@builtin "string.ne"
@builtin "whitespace.ne"
