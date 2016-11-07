program     -> _ declaration:* _   {% (d) => d[1] %}
declaration -> _ function _ newline  {% (d, l) => [d[1], l] %}

function    -> "to" __ ident (__ "with" __ signature):? __ statement {% d => [d[2], (d[3] || [])[3] || [], d[5]] %}
signature -> "(" _ (ident (_ "," _ expression):*):? _ ")"

statement -> "return" __ expression {% (d) => [token.RETURN, d[2]] %}
           | "if" __ expression __ "then" __ statement {% (d) => [token.IF, d[2], d[6]] %}
           | "if" __ expression __ "then" __ statement __ "else" __ statement {% (d) => [token.IFELSE, d[2], d[6], d[10]] %}
           | "do" __ statement:* __ "end" {% (d) => [token.DO, d[2]] %}
           | ident "(" expressionlist:? ")" {% (d) => [token.CALL, d[0], d[2]] %}
           | "set" __ ident __ "to" __ expression {% (d) => [token.SET, d[2], d[6]] %}
           | "change" __ ident __ "by" __ expression {% (d) => [token.CHANGE, d[2], d[6]] %}
           | "forever" __ statement {% (d) => [token.FOREVER, d[2]] %}
           | "while" __ expression __ statement {% (d) => [token.WHILE, d[2], d[4]] %}
           | "for each" __ ident __ "in" __ range __ statement {% (d) => [token.FOREACH, d[2], d[6], d[8]] %}

range -> expression __ "to" __ expression (__ "by" __ expression):?
       | expression __ "through" __ expression (__ "by" __ expression):?

expressionlist -> expression (_ "," _ expression):* {% (d) => {
  console.dir(d, { depth: null })
  return d
}%}

expression -> term (_ addop _ term):*
term       -> sfactor (_ mullop _ sfactor):*
sfactor    -> (notop _):? factor
factor     -> __ int __
            | __ float __
            | __ ident __
            | "(" _ expression _ ")"
addop      -> "+"
            | "-"
            | __ "or" __
mulop      -> "*"
            | "/"
            | __ "and" __
notop      -> "-"
            | __ "not" __

int   -> [0-9]:+     {% (d) => parseInt(d[0].join('')) %}
float -> int "." int {% (d) => parseFloat(d.join('')) %}
ident -> [a-zA-Z_]:+ {% (d) => d[0].join('') %}

newline -> "\r\n"
         | "\n"

@builtin "whitespace.ne"
