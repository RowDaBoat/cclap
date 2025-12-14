# ISC License
# Copyright (c) 2025 RowDaBoat

import config
import tables
import sequtils
import strutils


proc buildHelp*(namesInOrder: seq[string], definitions: Table[string, Config]): string =
  var table: seq[(string, string, string, string)] = @[
    ("Options", "Type", "Default", "Help")
  ]
  var optionsWidth = table[0][0].len
  var typesWidth = table[0][1].len
  var defaultsWidth = table[0][2].len

  for name in namesInOrder:
    var config = definitions[name]
    var short = if config.short != '\0': "-" & $config.short else: ""
    var long = if config.long != "": "--" & $config.long else: ""
    var options = @[short, long].filterIt(it != "").join(",")
    optionsWidth = max(optionsWidth, options.len)

    var typ = config.typ
    typesWidth = max(typesWidth, typ.len)

    var default = config.default
    defaultsWidth = max(defaultsWidth, default.len)

    table.add((options, typ, config.default, config.help))

  for (options, typ, a, help) in table:
    result &= options.alignLeft(optionsWidth) & "  "
    result &= typ.alignLeft(typesWidth) & "  "
    result &= a.alignLeft(defaultsWidth) & "  "
    result &= help & "\n"
