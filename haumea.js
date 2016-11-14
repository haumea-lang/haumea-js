#! /usr/bin/env node

const token = require('./token')
const compile = require('./compile')

const make = require('nearley-make')
const chalk = require('chalk')
const program = require('commander')
const fs = require('fs')
const ms = require('ms')

const grammar = fs.readFileSync(__dirname + '/grammar.ne', 'utf8')
const parser = make(grammar, { token })

program
  .version(require('./package.json').version)
  .arguments('<file>')
  .description(chalk.magenta('Compiles the given file to JavaScript'))
  .option('-o, --output <file>', 'Output file')
  .action(file => {
    if (file === 'undefined') {
      console.error(chalk.red(chalk.bold('Fatal error: ') + 'no input file provided'))
      process.exit(1)
    } else if (!program.output) {
      console.error(chalk.red(chalk.bold('Fatal error: ') + 'no output file provided'))
      process.exit(1)
    } else {
      try {
        var input = fs.readFileSync(file, 'utf8')
      } catch (e) {
        if (e.code === 'ENOENT')
          console.error(chalk.red(chalk.bold('Fatal error: ') + `failed to read input file ${chalk.white(file)}: doesn't exist`))
        else
          console.error(chalk.red(chalk.bold('Fatal error: ') + `failed to read input file ${chalk.white(file)}: ${e.code}`))
        process.exit(1)
      }

      const then = Date.now()

      const trees = parser.feed(input).results
      const out = compile(trees[0], function panic(err) {
        console.error(chalk.red(chalk.bold('Fatal error: ') + err))
        process.exit(1)
      })

      try {
        fs.writeFileSync(program.output, out, 'utf8')
        const time = Date.now() - then
        console.log(chalk.green(chalk.bold('Done ') + 'in ' + ms(time)))
      } catch (e) {
        panic(`failed to write output file ${chalk.white(file)}: ${e.code}`)
      }
    }
  })
  .parse(process.argv)

if (program.args.length < 1) {
  // no args
  program.help()
}
