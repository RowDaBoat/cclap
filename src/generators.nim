# ISC License
# Copyright (c) 2025 RowDaBoat

import config
import tables
import sequtils
import strutils
import options


proc generateUsage*(program: string, namesInOrder: seq[string], definitions: Table[string, Config]): string =
  result = "Usage: " & program

  for name in namesInOrder:
    var config = definitions[name]

    if config.usage.isSome and config.usage.get == "":
      result &= " --" & config.long
    elif config.usage.isSome:
      result &= " --" & config.long & "=" & config.usage.get


proc generateConfig*(namesInOrder: seq[string], definitions: Table[string, Config]): string =
  var table: seq[(string, string, string)]
  var configWidth = 0

  for name in namesInOrder:
    var config = definitions[name]

    if config.mode in {Mode.config, Mode.both}:
      configWidth = max(configWidth, config.long.len)
      table.add((config.long, config.default, config.help))

  for (config, default, help) in table:
    result &= "# " & help & "\n"
    let alignedConfig = config.alignLeft(configWidth)
    result &= "# " & alignedConfig & " = " & default & " \n\n"


proc generateHelp*(namesInOrder: seq[string], definitions: Table[string, Config]): string =
  var table: seq[(string, string, string, string)] = @[
    ("Options", "Type", "Default", "Help")
  ]
  var optionsWidth = table[0][0].len
  var typesWidth = table[0][1].len
  var defaultsWidth = table[0][2].len

  for name in namesInOrder:
    var config = definitions[name]

    if config.mode in {Mode.option, Mode.both}:
      var short = if config.short != '\0': "-" & $config.short else: ""
      var long = if config.long != "": "--" & $config.long else: ""
      var options = @[short, long].filterIt(it != "").join(",")
      optionsWidth = max(optionsWidth, options.len)

      var typ = config.typ
      typesWidth = max(typesWidth, typ.len)

      var default = config.default
      defaultsWidth = max(defaultsWidth, default.len)

      table.add((options, typ, config.default, config.help))

  for (options, typ, default, help) in table:
    result &= options.alignLeft(optionsWidth) & "  "
    result &= typ.alignLeft(typesWidth) & "  "
    result &= default.alignLeft(defaultsWidth) & "  "
    result &= help & "\n"
