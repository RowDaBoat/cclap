# ISC License
# Copyright (c) 2025 RowDaBoat

import strutils
import strformat
import tables
import typetraits
import sequtils
import macros
import configsFrom
import config
import help
import errors


type Cclap*[T] = object
  namesInOrder: seq[string]
  configDefinitions: Table[string, Config]
  default: T
  args: Table[string, string]
  configs: Table[string, string]


template help*(message: string) {.pragma.}
  ## Help message for the option.


template shortOption*(opt: char) {.pragma.}
  ## Short option alternative for the option.


proc parseLongOption(arg: string, args: var Table[string, string]) =
  let split = arg.split("=", maxsplit=1)
  let name = split[0][2..^1]

  if split.len < 2:
    args[name] = "true"
  elif name in args:
    args[name] &= "," & split[1]
  else:
    args[name] = split[1]


proc parseShortOptions(arg: string, args: var Table[string, string]) =
  let split = arg[1..^1].split("=", maxsplit=1)
  let singles = split[0]

  if split.len < 2:
    args[$singles] = "true"
  
    for single in singles:
      args[$single] = "true"
  elif singles.len == 1:
    args[$singles] = split[1]
  else:
    invalidShortOptions(arg)


proc showEnum[T: enum](value: T): string =
  typeof(value).mapIt(fmt"{it}").join("|")


proc showEnumList[T: enum](value: seq[T]): string =
  showEnum(default(T))


proc setFieldValue[T](name: string, fieldValue: var T, strValue: string, chosen: ConfigSource) =
  if chosen == Default:
    return

  var stripped = strValue.strip

  when fieldValue is bool:
    try: fieldValue = parseBool(stripped)
    except: invalidValue(name, stripped, chosen, "is not true or false")
  elif fieldValue is int:
    try: fieldValue = parseInt(stripped)
    except: invalidValue(name, stripped, chosen, "is not an integer number")
  elif fieldValue is float:
    try: fieldValue = parseFloat(stripped)
    except: invalidValue(name, stripped, chosen, "is not a floating point number")
  elif fieldValue is enum:
    try: fieldValue = parseEnum[typeof(fieldValue)](stripped)
    except: invalidValue(name, stripped, chosen, "is not one of: " & showEnum(fieldValue))
  elif fieldValue is string:
    fieldValue = stripped
  elif fieldValue is seq[bool]:
    try: fieldValue = strValue.split(",").mapIt(parseBool(it.strip))
    except: invalidValue(name, strValue, chosen, "contains elements that are not true or false")
  elif fieldValue is seq[int]:
    try: fieldValue = strValue.split(",").mapIt(parseInt(it.strip))
    except: invalidValue(name, strValue, chosen, "contains elements that are not integer numbers")
  elif fieldValue is seq[float]:
    try: fieldValue = strValue.split(",").mapIt(parseFloat(it.strip))
    except: invalidValue(name, strValue, chosen, "contains elements that are not floating point numbers")
  elif fieldValue is seq[enum]:
    try: fieldValue = strValue.split(",").mapIt(parseEnum[typeof(fieldValue[0])](it.strip))
    except: invalidValue(name, strValue, chosen, "contains elements that are not one of: " & showEnumList(fieldValue))
  elif fieldValue is seq[string]:
    fieldValue = strValue.split(",").mapIt(it.strip)
  else:
    {.error: "cclap: '" & $typeof(fieldValue) & "' is not supported for field: '" & name & "'."}


proc stringType[T](value: T): string =
  const listDescription = "',' separated list of: "

  when value is bool:
    return "true|false"
  elif value is int:
    return "int number"
  elif value is float:
    return "float number"
  elif value is string:
    return "text"
  elif value is enum:
    return showEnum(value)
  elif value is seq[bool]:
    return listDescription & "true|false"
  elif value is seq[int]:
    return listDescription & "int number"
  elif value is seq[float]:
    return listDescription & "float number"
  elif value is seq[string]:
    return listDescription & "text"
  elif value is seq[enum]:
    return listDescription & showEnumList(value)


proc stringDefault[T](value: T): string =
  if value is seq:
    return ($value)[2..^2]
  else:
    return $value


proc initCclap*[T: object](default: T = default(T)): Cclap[T] =
  ## Initialize Cclap, optionally with the default configurations.

  var namesInOrder: seq[string]
  let configs = configsFrom(T)
  var configsTable: Table[string, Config]

  for name, value in default.fieldPairs:
    when not (value is bool | int | float | enum | string | seq[bool] | seq[int] | seq[float] | seq[enum] | seq[string]):
      {.error: "cclap: '" & $typeof(value) & "' is not supported for field: '" & name & "'."}

  for config in configs:
    namesInOrder.add(config.long)
    configsTable[config.long] = config

  for name, val in default.fieldPairs:
    configsTable[name].typ = stringType(val)
    configsTable[name].default = stringDefault(val)

  result = Cclap[T](
    namesInOrder: namesInOrder,
    configDefinitions: configsTable,
    default: default
  )


proc parseOptions*[T: object](self: var Cclap[T], args: seq[string]): seq[string] =
  ## Parse command line options, the result is the remaining arguments from the first non-option argument.
  ## raises an `InvalidShortOptions` error if the short options are ill-formed ex: -abc=def.

  var remaining = args

  while remaining.len > 0:
    let arg = remaining[0]

    if arg == "--":
      return remaining[1..^1]
    elif arg.startsWith("--"):
      parseLongOption(arg, self.args)
    elif arg.startsWith("-"):
      parseShortOptions(arg, self.args)
    else:
      return remaining

    remaining = remaining[1..^1]

  return remaining


proc parseConfig*[T: object](self: var Cclap[T], config: string) =
  ## Parse configurations from a string.
  ## The config string is a list of key=value pairs separated by newlines.
  ## The `config` parameter is usually the contents of a configuration file.
  ## Lines starting with `#` are ignored.

  let configs = config.splitLines()
    .mapIt(it.strip)
    .filterIt(it.len > 0 and it[0] != '#')
    .mapIt(it.split('=', maxsplit=1))

  for config in configs:
    let name = config[0].strip

    if config.len == 1:
      self.configs[name] = "true"
    elif name in self.configs:
      self.configs[name] &= "," & config[1].strip
    else:
      self.configs[name] = config[1].strip


proc config*[T: object](self: var Cclap[T]): T =
  ## Get the parsed configurations into a configuration object.
  ## Arguments, configurations and defaults, are merged in that order of priority.
  ## raises an `InvalidValue` error if an option of an argument or configuration is not valid for the field type.
  ## 

  result = self.default

  for name, value in result.fieldPairs:
    var chosen = Default
    var stringValue = ""
    var short = self.configDefinitions[name].short

    if name in self.args:
      chosen = Args
      stringValue = self.args[name]
    elif short != '\0' and $short in self.args:
      chosen = Args
      stringValue = self.args[$short]
    elif name in self.configs:
      chosen = ConfigFile
      stringValue = self.configs[name]

    setFieldValue(name, value, stringValue, chosen)


proc unknownArgs*[T](self: var Cclap[T]): seq[string] =
  ## Get the user's arguments that do not belong to the configuration object.

  for arg in self.args.keys:
    if not (arg in self.configDefinitions):
      result.add(arg)


proc unknownConfigs*[T](self: var Cclap[T]): seq[string] =
  ## Get the user's configurations that do not belong to the configuration object.

  for config in self.configs.keys:
    if not (config in self.configDefinitions):
      result.add(config)


proc help*[T: object](self: Cclap[T]): string =
  return buildHelp(self.namesInOrder, self.configDefinitions)
