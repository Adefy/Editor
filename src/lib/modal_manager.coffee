define (require) ->

  class ModalManager

    constructor: (@ui) ->
      #

    ###
    # @return [Modal]
    ###
    showModalRename: (asset) ->
      nameId = ID.prefId "fileName"

      _html = TemplateModalRename
        nameId: nameId
        name: asset.getName()

      new Modal
        title: "Rename",
        mini: true,
        content: _html,
        modal: false,

        cb: (data) =>
          # Submission
          name = data[nameId]
          asset.setName name
          @ui.pushEvent "update.asset", asset: asset

        validation: (data) =>
          # Validation
          name = data[nameId]
          unless name.length > 0 then return "Name must be longer than 0"
          true

        change: (deltaName, deltaVal, data) =>
          #$("input[name=\"#{nameId}\"]").val deltaVal