gulp = require "gulp"
coffee = require "gulp-coffee"
rename = require "gulp-rename"
stylus = require "gulp-stylus"
minifycss = require "gulp-minify-css"

paths =
  lib: "src/lib/**/*.coffee"
  styl: "src/styles/**/*.styl"

# Compile stylus
gulp.task "stylus", ->
  gulp.src paths.styl
  .pipe stylus "include css": true
  .pipe rename suffix: ".min"
  .pipe minifycss()
  .pipe gulp.dest "src/build/css"

# Compile clientside coffeescript
gulp.task "coffee", ->
  gulp.src paths.lib
  .pipe coffee()
  .pipe gulp.dest "src/build/lib"

# Rerun the task when a file changes
gulp.task "watch", ->
  gulp.watch paths.lib, ["coffee"]
  gulp.watch paths.styl, ["stylus"]

# Build all of the assets
gulp.task "build", ["stylus", "coffee"]

# Run in development
gulp.task "develop", ["build", "watch"]

# The default task (called when you run `gulp` from cli)
gulp.task "default", ["build"]
