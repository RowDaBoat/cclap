# ISC License
# Copyright (c) 2025 RowDaBoat

import ../cclap
import strutils
import os
import tables
import sequtils


type Enclose = enum none, paren, brackets, braces, angle
type Emojis = enum happy, world, fire, wave

type Configuration = object
  help {.
    help: "Show this help",
    shortOption: 'h',
    mode: option
  .} : bool

  uppercase {.
    help: "Uppercase the output",
    shortOption: 'u',
  .} : bool

  times {.
    help: "Times to repeat",
    shortOption: 't'
    usage: "1"
  .} : int

  name {.
    help: "Names to salute"
#    required
    usage: "name1,...,nameN"
  .} : seq[string]

  enclose {.
    help: "Enclose the output"
    usage: "brackets"
  .} : Enclose

  emoji {.
    help: "Use emojis in salutation"
    usage: "happy,world,fire,wave"
  .} : seq[Emojis]


var cli = initCclap(Configuration(
  uppercase: false,
  times: 5,
  name: @["world"],
  enclose: none
))
discard cli.parseOptions(commandLineParams())
let configuration = cli.config()


for arg in cli.unknownOptions():
  echo "Warning: unknown argument: ", arg

for config in cli.unknownConfigs():
  echo "Warning: unknown configuration: ", config

if configuration.help:
  echo cli.generateHelp()
  quit(0)

let enclosers = {
  Enclose.none: "",
  Enclose.paren: "()",
  Enclose.brackets: "[]",
  Enclose.braces: "{}",
  Enclose.angle: "<>"
}.toTable

let emojis = {
  Emojis.happy: "😊",
  Emojis.world: "🌍",
  Emojis.fire: "🔥",
  Emojis.wave: "🌊"
}.toTable

for i in 0..<configuration.times:
  let salute = "Hello " & configuration.name.join(", ") & "!"
  let encloser = enclosers[configuration.enclose]
  let (open, close) = if encloser.len == 2: ($encloser[0], $encloser[1]) else: ("", "")
  let salutation = if configuration.uppercase: salute.toUpper else: salute
  let emoji = configuration.emoji.mapIt(emojis[it]).join("")
  echo open & salutation & emoji & close

echo cli.generateUsage()
echo cli.generateConfig()
