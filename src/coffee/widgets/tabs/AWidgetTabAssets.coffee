
# @depend AWidgetTab.coffee

class AWidgetTabAssets extends AWidgetTab

  constructor: (parent) ->
    super parent
    @addedParentClass = "files"

  render: ->
    # horrible horrible place holder, someone shoot me pls
    _html = @genElement "dl", {}, =>
      __html = @genElement "dt", {}, =>
        @genElement "i", class: "fa fa-fw fa-caret-right"
      __html+= @genElement "dd", {}, =>
        @genElement("i", class: "fa fa-fw fa-folder") + "Directory"

    _html+= @genElement "dl", {}, =>
      __html = @genElement "dt", {}, =>
        @genElement "i", class: "fa fa-fw fa-caret-down"

      __html+= @genElement "dd", {}, =>
        @genElement("i", class: "fa fa-fw fa-folder") + "Directory" +
        @genElement "dl", {}, =>
          ___html = @genElement "dt", {}, =>
            @genElement "i", class: "fa fa-fw fa-caret-down"

          ___html += @genElement "dd", {}, =>
            @genElement("i", class: "fa fa-fw fa-folder") + "Directory" +
            @genElement "dl", {}, =>
              ____html = @genElement "dt", {}, =>
                @genElement "i", class: "fa fa-fw fa-caret-down"

              ____html += @genElement "dd", {}, =>
                @genElement("i", class: "fa fa-fw fa-folder") + "Directory" +
                @genElement "dl", {}, =>
                  _____html = @genElement "dl", {}, =>
                    @genElement("i", class: "fa fa-fw")
                  _____html+= @genElement "dd", {}, =>
                    @genElement("i", class: "fa fa-fw fa-file") + "file.jpg"

    _html+= @genElement "dl", {}, =>
      __html = @genElement "dt", {}, =>
        @genElement "i", class: "fa fa-fw"
      __html+= @genElement "dd", {}, =>
        @genElement("i", class: "fa fa-fw fa-file") + "Ad.jpg"