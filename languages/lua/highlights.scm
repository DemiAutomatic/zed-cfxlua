; Keywords
"return" @keyword.return

[
  "goto"
  "in"
  "local"
] @keyword

(label_statement) @label

(break_statement) @keyword

(do_statement
  ["do" "end"] @keyword)

(while_statement
  ["while" "do" "end"] @keyword)

(repeat_statement
  ["repeat" "until"] @keyword)

(if_statement
  ["if" "elseif" "else" "then" "end"] @keyword)

(elseif_statement
  ["elseif" "then" "end"] @keyword)

(else_statement
  ["else" "end"] @keyword)

(for_statement
  ["for" "do" "end"] @keyword)

(function_declaration
  ["function" "end"] @keyword.function)

(function_definition
  ["function" "end"] @keyword.function)

; Operators
(binary_expression
  operator: _ @operator)

(unary_expression
  operator: _ @operator)

"=" @operator

(augmented_assignment_operator) @operator   ; += etc.

[
  "and"
  "not"
  "or"
] @keyword.operator

; Punctuations
[
  ";"
  ":"
  ","
  "."
] @punctuation.delimiter

; Brackets
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

; Safe nav
"?." @punctuation.delimiter
"?[" @punctuation.bracket

; Variables
(identifier) @variable

((identifier) @variable.builtin
  (#eq? @variable.builtin "self"))

(variable_list
  (attribute
    "<" @punctuation.bracket
    (identifier) @attribute
    ">" @punctuation.bracket))

; Constants
((identifier) @constant
  (#match? @constant "^[A-Z][A-Z_0-9]*$"))

(vararg_expression) @constant

(nil) @constant.builtin

[
  (false)
  (true)
] @boolean

; Hash literals (CfxLua compile-time joaat)
(hash_literal) @string.special

; Tables / Sets
(field
  name: (identifier) @field)

(dot_index_expression
  field: (identifier) @field)

(safe_dot_index_expression
  field: (identifier) @field)

(table_constructor
  ["{" "}"] @constructor)

; Set shorthand .field  (value omitted => true)
(field
  "." @punctuation.delimiter
  name: (identifier) @field)

; Functions
(parameters
  (identifier) @parameter)

(function_declaration
  name: [
    (identifier) @function
    (dot_index_expression field: (identifier) @function)
  ])

(function_declaration
  name: (method_index_expression
    method: (identifier) @function.method))

(assignment_statement
  (variable_list
    .
    name: [
      (identifier) @function
      (dot_index_expression field: (identifier) @function)
    ])
  (expression_list
    .
    value: (function_definition)))

(table_constructor
  (field
    name: (identifier) @function
    value: (function_definition)))

(function_call
  name: [
    (identifier) @function.call
    (dot_index_expression field: (identifier) @function.call)
    (method_index_expression method: (identifier) @function.method)
  ])

; CfxLua / FiveM common builtin constructors and libraries (highlight as functions)
(function_call
  (identifier) @function.builtin
  (#any-of? @function.builtin
    ; standard
    "assert" "collectgarbage" "dofile" "error" "getfenv" "getmetatable" "ipairs" "load" "loadfile"
    "loadstring" "module" "next" "pairs" "pcall" "print" "rawequal" "rawget" "rawset" "require"
    "select" "setfenv" "setmetatable" "tonumber" "tostring" "type" "unpack" "xpcall"
    ; CfxLua / GLM first-class + common
    "vec" "vec2" "vec3" "vec4" "ivec" "ivec2" "ivec3" "ivec4" "bvec" "bvec2" "bvec3" "bvec4"
    "quat" "qua"
    "mat" "mat2" "mat3" "mat4" "mat2x2" "mat2x3" "mat2x4" "mat3x2" "mat3x3" "mat3x4" "mat4x2" "mat4x3" "mat4x4"
    ; other common Cfx
    "joaat" "exports" "promise" "json" "msgpack"
    "vector2" "vector3" "vector4"
    "each"
  ))

; Others
(comment) @comment

(hash_bang_line) @preproc

(number) @number

(string) @string

(escape_sequence) @string.escape
