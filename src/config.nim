# ISC License
# Copyright (c) 2025 RowDaBoat

type Config* = object
  long*: string
  short*: char
  typ*: string
  default*: string
  help*: string

type ConfigSource* = enum Args, ConfigFile, Default
