# ISC License
# Copyright (c) 2025 RowDaBoat

import tables
import macros
import config


proc getTypeDef(T: NimNode): NimNode =
  result = getTypeInst(T)[1].getImpl

  if result.kind != nnkTypeDef:
    error "cclap: the provided type is not an object."


proc getObjDef(typeDef: NimNode): NimNode =
  result = typeDef[2]

  if result.kind != nnkObjectTy:
    error "cclap: the provided type is not an object."


proc getFields(T: NimNode): NimNode =
  let typeDef = getTypeDef(T)
  let objDef = getObjDef(typeDef)
  result = objDef[2]


proc namesAndPragmas(field: NimNode): (NimNode, NimNode) =
  if field[0].kind == nnkPragmaExpr:
    result[0] = field[0][0]
    result[1] = field[0][1]
  else:
    result[0] = field[0]
    result[1] = nil


proc getFieldName(names: NimNode): string =
  if names.kind != nnkIdent:
    error "cclap: only a single name per field is allowed in the configuration object."

  result = $names


proc getHelp(pragma: NimNode): string =
  if (pragma.kind != nnkCall and pragma.kind != nnkExprColonExpr) or pragma.len != 2:
    error "cclap: help pragma must have a single argument"

  let helpMsg = pragma[1]

  if not (helpMsg.kind in {nnkStrLit, nnkRStrLit, nnkTripleStrLit}):
    error "cclap: help pragma must have a string argument"

  result = helpMsg.strVal


proc getShortOption(pragma: NimNode): char =
  if (pragma.kind != nnkCall and pragma.kind != nnkExprColonExpr) or pragma.len != 2:
    error "cclap: shortOption pragma must have a single argument"

  let shortOptChar = pragma[1]
  if not (shortOptChar.kind == nnkCharLit):
    error "cclap: shortOption pragma must have a char literal argument"

  result = chr(shortOptChar.intVal)


proc processPragmas(pragmas: NimNode): (string, char) =
  var helpText = ""
  var shortOpt = '\0'

  for pragma in pragmas:
    if $pragma[0] == "help":
      helpText &= getHelp(pragma)
    elif $pragma[0] == "shortOption":
      shortOpt = getShortOption(pragma)

  return (helpText, shortOpt)


proc addd(configs: NimNode, field: NimNode): NimNode =
  var (names, pragmas) = namesAndPragmas(field)
  var fieldName = getFieldName(names)
  var shortOpt = '\0'
  var helpText = ""

  if pragmas != nil and pragmas.kind == nnkPragma:
    (helpText, shortOpt) = processPragmas(pragmas)

  result = quote do:
    `configs`.add(Config(
      long: `fieldName`,
      short: `shortOpt`,
      help: `helpText`
    ))


macro configsFrom*(T: typedesc): untyped =
  result = newStmtList()

  let configs = genSym(nskVar, "configObj")

  result.add quote do:
    var `configs`: seq[Config] = @[]

  let fields = getFields(T)

  for field in fields:
    if field.kind == nnkIdentDefs:
      result.add addd(configs, field)

  result.add(configs)
