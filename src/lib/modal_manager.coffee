define (require) ->

  Project = require "project"
  param = require "util/param"
  ID = require "util/id"

  Storage = require "storage"

  Asset = require "handles/asset"
  Texture = require "handles/texture"
  BaseActor = require "handles/actors/base"
  Handle = require "handles/handle"

  EditorObject = require "editor_object"

  FloatingTextureSelect = require "widgets/floating/texture_select"
  Modal = require "widgets/floating/form"
  SettingsWidget = require "widgets/floating/settings"


  TemplateModalAddTextures = require "templates/modal/add_textures"
  TemplateModalBackgroundColor = require "templates/modal/background_color"
  TemplateModalEditHistory = require "templates/modal/edit_history"
  TemplateModalHelpAbout = require "templates/modal/help_about"
  TemplateModalHelpChangeLog = require "templates/modal/change_log"
  TemplateModalPrefSettings = require "templates/modal/pref_settings"
  TemplateModalRename = require "templates/modal/rename"
  TemplateModalSetPreviewFPS = require "templates/modal/set_preview_fps"
  TemplateModalWorkspaceScreenSize = require "templates/modal/screen_size"
  TemplateModalOpenProject = require "templates/modal/open_project"

  ChangeLog = require "info_change_log"
  Version = require "version"

  class ModalManager extends EditorObject

    constructor: (@ui) ->
      #

    ###
    # @param [Handle] handle
    # @param [Object] options
    #   @optional
    #   @property [Array<String>] unique
    #     @optional
    #   @property [Function] cb
    #     @optional
    # @return [Modal]
    ###
    showRename: (handle, options) ->

      options = param.optional options, {}

      nameId = ID.prefID "fileName"

      _html = TemplateModalRename
        nameId: nameId
        name: handle.getName()

      new Modal @ui,
        title: "Rename"
        mini: true
        content: _html

        cb: (data) =>
          # Submission
          name = data[nameId]

          if cb = options.cb
            cb handle, name
          else
            handle.setName name
            if handle instanceof Asset
              @ui.pushEvent "renamed.asset", asset: handle
            else if handle instanceof BaseActor
              @ui.pushEvent "renamed.actor", actor: handle
            else if handle instanceof Handle
              @ui.pushEvent "renamed.handle", handle: handle

        validation: (data) =>
          # Validation
          name = data[nameId]

          if cb = options.validate
            cb handle, name
          else
            if options.unique
              isUnique = _.all options.unique, (n) -> n != name
              return "Name must be unique!" unless isUnique

            unless name.length > 0 then return "Name must be longer than 0"
            true

        change: (deltaName, deltaVal, data) =>
          #$("input[name=\"#{nameId}\"]").val deltaVal

        ## MODALS

    ###
    # Show dialog box for setting the preview framerate
    # @return [Modal]
    ###
    showSetPreviewRate: ->

      # Randomized input name
      name = ID.prefID "_tPreviewRate"

      new Modal @ui,
        title: "Set Preview Framerate"
        content: TemplateModalSetPreviewFPS
          previewFPS: @ui.timeline.getPreviewFPS()
          name: name

        cb: (data) => @ui.timeline._previewFPS = data[name]
        validation: (data) ->
          return "Framerate must be a number" if isNaN data[name]
          return "Framerate must be > 0" if data[name] <= 0
          true

    ###
    # TODO
    # Show dialog box for setting the export framerate
    # @return [Modal]
    ###
    showSetExportRate: ->

      # Randomized input name
      name = ID.prefID "_tPreviewRate"

      new Modal @ui,
        title: "Set Export Framerate"
        content: TemplateModalSetPreviewFPS
          previewFPS: @ui.timeline.getPreviewFPS()
          name: name

        cb: (data) =>
          #@ui.timeline._previewFPS = data[name]

        validation: (data) ->
          return "Framerate must be a number" if isNaN data[name]
          return "Framerate must be > 0" if data[name] <= 0
          true

    ###
    # Shows a modal allowing the user to set screen properties. Sizes are picked
    # from device templates, rotation and scale are also available
    ###
    showSetScreenProperties: ->

      workspace = @ui.workspace

      curScale = ID.prefID "_wspscale"
      cSize = ID.prefID "_wspcsize"
      pSize = ID.prefID "_wsppsize"
      pOrie = ID.prefID "_wsporientation"

      curSize = "#{workspace._pWidth}x#{workspace._pHeight}"
      chL = ""
      chP = ""

      if workspace._pOrientation == "land" then chL = "checked=\"checked\""
      else chP = "checked=\"checked\""

      new Modal @ui,
        title: "Set Screen Properties"
        content: TemplateModalWorkspaceScreenSize
          cSize: cSize
          pSize: pSize
          pOrie: pOrie
          chL: chL
          chP: chP
          curScale: curScale
          pScale: workspace._pScale
          currentSize: curSize

        cb: (data) =>
          # Submission
          size = data[cSize].split "x"

          workspace._pHeight = Number size[1]
          workspace._pWidth = Number size[0]
          workspace._pScale = Number data[curScale]
          workspace._pOrientation = data[pOrie]
          workspace.updateOutline()

        validation: (data) =>
          # Validation
          size = data[cSize].split "x"

          if size.length != 2 then return "Size is of the format WidthxHeight"
          else if isNaN(size[0]) or isNaN(size[1])
            return "Dimensions must be numbers"
          else if isNaN(data[curScale]) then return "Scale must be a number"

          true
        change: (deltaName, deltaVal, data) =>

          if deltaName == pSize
            $("input[name=\"#{cSize}\"]").val deltaVal.split("_").join "x"

    ###
    # Creates and shows the "Set Background Color" modal
    # @return [Modal]
    ###
    showSetBackgroundColor: ->

      workspace = @ui.workspace

      col = workspace._are.getClearColor()

      _colR = col.getR()
      _colG = col.getG()
      _colB = col.getB()

      valHex = _colB | (_colG << 8) | (_colR << 16)
      valHex = (0x1000000 | valHex).toString(16).substring 1

      preview = ID.prefID "_wbgPreview"
      hex = ID.prefID "_wbgHex"
      r = ID.prefID "_wbgR"
      g = ID.prefID "_wbgG"
      b = ID.prefID "_wbgB"

      pInitial = "background-color: rgb(#{_colR}, #{_colG}, #{_colB});"

      _html =

      new Modal @ui,
        title: "Set Background Color"
        content: TemplateModalBackgroundColor
          hex: hex
          hexstr: valHex
          r: r
          g: g
          b: b
          colorRed: _colR
          colorGreen: _colG
          colorBlue: _colB
          preview: preview
          pInitial: pInitial

        cb: (data) =>
          # Submission
          workspace._are.setClearColor data[r], data[g], data[b]

        validation: (data) =>
          # Validation
          vR = data[r]
          vG = data[g]
          vB = data[b]

          if isNaN(vR) or isNaN(vG) or isNaN(vB)
            return "Components must be numbers"
          else if vR < 0 or vG < 0 or vB < 0 or vR > 255 or vG > 255 or vB > 255
            return "Components must be between 0 and 255"

          true
        change: (deltaName, deltaVal, data) =>

          cH = data[hex]
          cR = data[r]
          cG = data[g]
          cB = data[b]

          delta = {}

          # On change
          if deltaName == hex

            # Recover rgb from hex
            cH = cH.substring 1
            _r = cH.substring 0, 2
            _g = cH.substring 2, 4
            _b = cH.substring 4, 6

            delta[hex] = cH
            delta[r] = parseInt _r, 16
            delta[g] = parseInt _g, 16
            delta[b] = parseInt _b, 16

          else

            # Build hex from rgba
            newHex = cB | (cG << 8) | (cR << 16)
            newHex = (0x1000000 | newHex).toString(16).substring 1

            delta[hex] = "##{newHex}"
            delta[r] = data[r]
            delta[g] = data[g]
            delta[b] = data[b]

          # Apply bg color to preview
          rgbCol = "rgb(#{delta[r]}, #{delta[g]}, #{delta[b]})"
          $("##{preview}").css "background-color", rgbCol

          # Return updates
          delta

    ###
    # Creates and shows the "Add Textures" modal
    # @return [Modal]
    ###
    showAddTextures: ->

      workspace = @ui.workspace

      textnameID = ID.prefID "_wtexture"
      textpathID = ID.prefID "_wtext"

      new Modal @ui,
        title: "Add Textures ..."
        content: TemplateModalAddTextures
          textnameID: textnameID
          textpathID: textpathID
          textname: ""
          textpath: ""

        cb: (data) =>
          #Submission
          workspace._uploadTextures data[textnameID], data[textpathID]

        validation: (data) =>
          if data[textnameID] == ""
            return "Texture must have a name"

          if data[textpathID] == null or data[textpathID] == ""
            return "You must select a texture"

          true

    ###
    # Set
    # @return [Modal]
    ###
    showSetTexture: (actor) ->

      textures = _.map @ui.editor.project.textures, (texture) ->
        {
          uid: texture.getUID()
          url: texture.getURL()
          name: texture.getName()
        }

      new FloatingTextureSelect @ui, textures, actor

    ###
    # @return [Void]
    ###
    showUploadTextures: (options) ->

      options = param.optional options, {}

      filepicker.pickAndStore
        mimetype: "image/*"
      ,
        location: "S3"
        path: Project.getS3Prefix()
      , (blob) =>
        textures = []

        for obj in blob
          texture = new Texture Project.current,
            key: obj.key
            name: obj.filename

          @ui.editor.project.textures.push texture
          textures.push texture

        @ui.workspace.loadTextures(textures)
        @ui.pushEvent "upload.textures", textures: textures

        cb blob if cb = options.cb

    ###
    # @return [Modal]
    ###
    showPrefSettings: ->

      new SettingsWidget @ui,
        title: "Preferences"
        settings: [
          label: "Autosave Frequency (s)"
          type: Number
          placeholder: "Enter an autosave frequency (s)"
          value: @ui.editor.settings.autosave.frequency / 1000
          id: "freq"
          min: 0
        ,
          label: "Preview Framerate"
          type: Number
          placeholder: "Enter a framerate (FPS)"
          value: @ui.timeline.getPreviewFPS()
          id: "preview_fps"
          min: 0
        ]
        cb: (data) =>
          @ui.editor.settings.autosave.frequency = data.freq * 1000
          @ui.editor.saveSettings()

          @ui.timeline.setPreviewFPS data.preview_fps

    showOpenProject: ->
      new Modal @ui,
        title: "Open Project"
        content: TemplateModalOpenProject()

    ###
    # @return [Modal]
    ###
    showEditHistory: ->

      new Modal @ui,
        title: "Edit History"
        content: TemplateModalEditHistory()

    ###
    # @return [Modal]
    ###
    showHelpAbout: ->

      new Modal @ui,
        title: "About"
        content: TemplateModalHelpAbout
          version: Version.STRING

    ###
    # @return [Modal]
    ###
    showHelpChangeLog: ->

      new Modal @ui,
        title: "Change Log"
        content: TemplateModalHelpChangeLog changes: ChangeLog.changes
