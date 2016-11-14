Object.assign(global, require('./token'))

//const shortid = require('shortid')
//shortid.characters('0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$_')

module.exports = function compile(tree, panic) {
  console.dir(tree, { depth: null, colors: true })

  let ind = ''

  function indent() {
    ind += 1
  }

  function outdent() {
    ind -= 1
  }

  let res = ''
  function add(what, k) {
    res += (k ? '' : '  '.repeat(ind)) + what
  }

  let idents = { display: 'console.log' }
  function gen(o) {
    if (idents[o]) return idents[o]

    const g = o // '_' + shortid.generate()
    idents[o] = g
    return g
  }

  for (let fn of tree) {
    if (fn.shift() !== FUNCTION) panic('Root declaration is not function')

    const [oldName, args, returnType, body] = fn
    const name = gen(oldName)

    add(`function ${name}(${args.map(a => gen(a[1]))}) {\n`)
    indent()

    statement(body)

    outdent()
    add(`}\n\n`)
  }

  function statement(d) {
    // Not using switch() {} here because it has weird syntax

    if (d[0] === DO) {
      const statements = d[1]
      d[1].forEach(s => statement(s))
    } else if (d[0] === CALL) {
      add(`${gen(d[1])}(${d[2].map(k => expression(k)).join(', ')})\n`)
    } else if (d[0] === DECLARATION) {
      add(`var ${gen(d[2])}\n`)
    } else if (d[0] === SET) {
      const is_declaration = d[1][0][0] === DECLARATION

      if (is_declaration) {
        add(`var `)
        d[1] = d[1][0][2]
      }

      add(`${gen(d[1])} = ${expression(d[2])}\n`, is_declaration)
    } else {
      panic(`Unknown statement type`)
    }
  }

  function expression(d) {
    if (d[0] === STRING) {
      return `"${d[1].replace(/"/g, '\\"')}"`
    } else if (d[0] === INTEGER || d[0] === FLOAT) {
      return `${d[1]}`
    } else if (d[0] === VARIABLE) {
      return `${gen(d[1])}`
    } else if (d[0] === ADD) {
      return `${expression(d[1])} + ${expression(d[2])}`
    } else if (d[0] === SUBTRACT) {
      return `${expression(d[1])} - ${expression(d[2])}`
    } else if (d[0] === DIVIDE) {
      return `${expression(d[1])} / ${expression(d[2])}`
    } else if (d[0] === MULTIPLY) {
      return `${expression(d[1])} * ${expression(d[2])}`
    } else {
      panic(`Unknown expression token`)
    }
  }

  add(`${gen('main')}()\n`)
  console.log('\n' + res)

  return res
}
