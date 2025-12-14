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
  help      {.help: "Show this help", shortOption: 'h'.}       : bool
  uppercase {.help: "Uppercase the output", shortOption: 'u'.} : bool
  times     {.help: "Times to repeat", shortOption: 't'.}      : int
  name      {.help: "Names to salute".}                        : seq[string]
  enclose   {.help: "Enclose the output".}                     : Enclose
  emoji     {.help: "Use emojis in salutation".}               : seq[Emojis]


var cli = initCclap(Configuration(
  uppercase: false,
  times: 5,
  name: @["world"],
  enclose: none
))
discard cli.parseArgs(commandLineParams())
let configuration = cli.config()


for arg in cli.unknownArgs():
  echo "Warning: unknown argument: ", arg

for config in cli.unknownConfigs():
  echo "Warning: unknown configuration: ", config

if configuration.help:
  echo cli.help()
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
  var (open, close) = if encloser.len == 2: ($encloser[0], $encloser[1]) else: ("", "")
  var salutation = if configuration.uppercase: salute.toUpper else: salute
  var emoji = configuration.emoji.mapIt(emojis[it]).join("")
  echo open & salutation & emoji & close
