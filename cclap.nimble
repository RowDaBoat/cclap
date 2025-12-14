packageName   = "cclap"
version       = "0.0.1"
author        = "RowDaBoat"
description   = "Configuration and Command Line Arguments Parser"
license       = "ISC"

srcDir        = "src"
binDir        = "bin"
skipDirs      = @["examples"]

requires "nim >= 2.0.0"

task examples, "Build examples":
  exec "nim c src/examples/example.nim"

task docs, "Generate documentation":
  exec "nim doc --project --git.url:git@github.com:RowDaBoat/cclap.git --index:on --outdir:docs src/cclap.nim"
