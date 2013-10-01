module.exports = (grunt) ->

  # Output
  libName = "aeditor.js"
  productionName = "aeditor-prod.min.js"

  # Directories
  buildDir = "build"
  libDir = "src"
  testDir = "test"
  devDir = "dev"
  docDir = "doc"
  awglDir = "../AdefyWebGL"
  adefyjsDir = "../AdefyJS"
  cdnDir = "../www/aeditor"
  production = "#{buildDir}/#{productionName}"

  productionConcat = [
    "#{devDir}/js/jquery.js"
    "#{devDir}/js/jquery-ui.js"
    "#{devDir}/js/underscore.min.js"
    "#{devDir}/js/sylvester.js"
    "#{devDir}/js/glUtils.js"
    "#{devDir}/js/mjax.min.js"
    "#{devDir}/js/gl-matrix-min.js"
    "#{devDir}/js/cp.min.js"

    "#{devDir}/js/awgl.js"
    "#{devDir}/js/adefy.js"
    "#{devDir}/aeditor.js"
  ]

  # Intermediate vars
  __awglOut = {}
  __awglOut["#{buildDir}/build-concat.coffee"] = [ "#{libDir}/coffee/AEditor.coffee" ]
  __awglOut["#{devDir}/build-concat.coffee"] = [ "#{libDir}/coffee/AEditor.coffee" ]

  __coffeeConcatFiles = {}

  # Build concat output
  __coffeeConcatFiles["#{buildDir}/#{libName}"] = "#{buildDir}/build-concat.coffee";

  # Dev concat output, used for browser testing
  __coffeeConcatFiles["#{devDir}/#{libName}"] = "#{buildDir}/build-concat.coffee";

  # 1 to 1 compiled files, for unit tests
  __coffeeFiles = [
    "#{libDir}/coffee/*.coffee"
    "#{libDir}/coffee/**/*.coffee"
  ]
  __testFiles = {}
  __testFiles["#{buildDir}/test/spec.js"] = [
    "#{testDir}/spec/*.coffee"
    "#{testDir}/spec/**/*.coffee"
  ]

  stylusSrc = {}
  stylusSrc["#{buildDir}/css/aeditor.css"] = "#{libDir}/stylus/style.styl"
  stylusSrc["#{devDir}/css/aeditor.css"] = "#{libDir}/stylus/style.styl"

  _uglify = {}
  _uglify[production] = production

  grunt.initConfig
    pkg: grunt.file.readJSON "package.json"
    coffee:
      concat:
        options:
          sourceMap: true
          bare: true
        cwd: buildDir
        files: __coffeeConcatFiles
      lib:
        expand: true
        options:
          bare: true
        src: [__coffeeFiles]
        dest: buildDir
        ext: ".js"
      tests:
        expand: true
        options:
          bare: true
        files: __testFiles

    coffeelint:
      app: __coffeeFiles

    concat_in_order:
      lib:
        files: __awglOut
        options:
          extractRequired: (path, content) ->

            workingDir = path.split "/"
            workingDir.pop()
            workingDir = workingDir.join().replace /,/g, "/"

            deps = @getMatches /\#\s\@depend\s(.*\.coffee)/g, content
            deps.forEach (dep, i) ->
              deps[i] = "#{workingDir}/#{dep}"

            return deps
          extractDeclared: (path) -> [path]
          onlyConcatRequiredFiles: true

    watch:
      awgl:
        files: ["#{awglDir}/build/awgl.js"]
        tasks: ["copy:awgl"]
      adefyjs:
        files: ["#{adefyjsDir}/build/adefy.js"]
        tasks: ["copy:adefyjs"]
      coffeescript:
        files: [
          "#{libDir}/**/*.coffee"
          "#{libDir}/*.coffee"
        ]
        tasks: ["concat_in_order", "coffee", "coffeelint"]
      stylus:
        files: [
          "#{libDir}/stylus/*.styl",
          "#{libDir}/stylus/**/*.styl"
        ]
        tasks: ["stylus"]

    connect:
      server:
        options:
          port: 8080
          base: "./"

    mocha:
      all:
        src: [ "#{buildDir}/#{testDir}/test.html" ]
        options:
          bail: false
          log: true
          reporter: "Nyan"
          run: true

    copy:
      test_page:
        files: [
          expand: true
          cwd: "#{testDir}/env"
          src: [ "**" ]
          dest: "#{buildDir}/#{testDir}"
        ]
      static:
        files: [
          expand: true
          cwd: "#{libDir}"
          src: [
            "static/**"
          ]
          dest: "#{buildDir}"
        ,
          expand: true
          cwd: "#{libDir}/static"
          src: [
            "**"
          ]
          dest: "#{devDir}"
        ]
      awgl:
        files: [
          expand: false
          src: "#{awglDir}/build/awgl.js"
          dest: "#{buildDir}/static/js/awgl.js"
        ,
          expand: false
          src: "#{awglDir}/build/awgl.js"
          dest: "#{devDir}/js/awgl.js"
        ,
          expand: false
          src: "#{awglDir}/build/awgl-concat.coffee"
          dest: "#{buildDir}/static/js/awgl-concat.coffee"
        ,
          expand: false
          src: "#{awglDir}/build/awgl.js.map"
          dest: "#{buildDir}/static/js/awgl.js.map"
        ,
          expand: false
          src: "#{awglDir}/build/awgl.js.map"
          dest: "#{devDir}/js/awgl.js.map"
        ,
          expand: false
          src: "#{awglDir}/build/awgl-concat.coffee"
          dest: "#{devDir}/js/awgl-concat.coffee"
        ]
      adefyjs:
        files: [
          expand: false
          src: "#{adefyjsDir}/build/adefy.js.map"
          dest: "#{buildDir}/static/js/adefy.js.map"
        ,
          expand: false
          src: "#{adefyjsDir}/build/adefy.js"
          dest: "#{buildDir}/static/js/adefy.js"
        ,
          expand: false
          src: "#{adefyjsDir}/build/ajs-concat.coffee"
          dest: "#{buildDir}/static/js/ajs-concat.coffee"
        ,
          expand: false
          src: "#{adefyjsDir}/build/adefy.js.map"
          dest: "#{devDir}/js/adefy.js.map"
        ,
          expand: false
          src: "#{adefyjsDir}/build/adefy.js"
          dest: "#{devDir}/js/adefy.js"
        ,
          expand: false
          src: "#{adefyjsDir}/build/ajs-concat.coffee"
          dest: "#{devDir}/js/ajs-concat.coffee"
        ]
      cdn:
        files: [
          expand: true
          cwd: docDir
          src: [ "**" ]
          dest: "#{cdnDir}/doc"
        ,
          src: "#{buildDir}/css/aeditor.css"
          dest: "#{cdnDir}/aeditor.css"
        ,
          src: "#{buildDir}/aeditor-prod.min.js"
          dest: "#{cdnDir}/aeditor.js"
        ]

    stylus:
      compile:
        files: stylusSrc

    clean: [
      buildDir
      docDir
    ]

    # Production concat
    concat:
      options:
        stripBanners: true
      dist:
        src: productionConcat
        dest: production

    uglify:
      options:
        preserveComments: false
      production:
        files: _uglify

  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-concat-in-order"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-stylus"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-mocha"

  grunt.registerTask "codo", "build html documentation", ->
    done = this.async()
    require("child_process").exec "codo", (err, stdout) ->
      grunt.log.write stdout
      done err

  # Perform a full build
  grunt.registerTask "default", [
    "concat_in_order"
    "coffee"
    "mocha"
    "stylus"
  ]
  grunt.registerTask "full", [
    "clean"
    "codo"
    "copy:test_page"
    "copy:static"
    "copy:awgl"
    "copy:adefyjs"
    "concat_in_order"
    "coffee"
    "stylus"
    "mocha"
  ]
  grunt.registerTask "dev", [
    "connect"
    "copy:test_page"
    "copy:static"
    "copy:awgl"
    "copy:adefyjs"
    "watch"
  ]

  grunt.registerTask "deploy", [ "concat", "uglify" ]
  grunt.registerTask "cdn", [ "full", "deploy", "copy:cdn" ]