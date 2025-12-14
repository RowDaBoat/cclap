# ISC License
# Copyright (c) 2025 RowDaBoat

import strformat
import config

type InvalidShortOptionsError* = object of ValueError
  arg*: string


type InvalidValueError* = object of ValueError
  configName*: string
  value*: string
  chosen*: ConfigSource
  expected*: string


proc invalidShortOptions*(arg: string) =
  raise (ref InvalidShortOptionsError)(
    msg: fmt"cclap: invalid short form arguments: '{arg}'",
    arg: arg
  )


proc invalidValue*(configName: string, value: string, chosen: ConfigSource, expected: string) =
  let typ = if chosen == Args: "argument" else: "configuration"
  raise (ref InvalidValueError)(
    msg: fmt"cclap: invalid value for {typ} '{configName}': '{value}' {expected}",
    configName: configName,
    value: value,
    chosen: chosen,
    expected: expected
  )


proc typeNotSupported*(typename: string) =
  raise newException(ValueError, fmt"cclap: type '{typename}' is not supported, this is a bug.")
