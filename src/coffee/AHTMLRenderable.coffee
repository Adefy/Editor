class AHTMLRenderable

  ###
  # @param [String] type
  # @param [Object] opts
  #   @option [Object] attrs Attributes to add to this element
  # @return [String] html
  ###
  genElement: (type, opts, cb) ->
    _html = ""
    _attrs = []
    if opts
      for k, v of opts
        _attrs.push "#{k}=\"#{v}\""

    _attr_str = ""
    _attr_str += " " + _attrs.join(" ") if _attrs.length > 0

    _html = "<#{type}#{_attr_str}>"
    _html += cb() if cb
    _html + "</#{type}>"

  ###
  # Convinienve method for creating buttons with icons in them
  # @param [String] iconName
  # @return [String] html
  ###
  genButtonIcon: (iconName, opts) ->
    attrs = {}
    attrs = opts.attrs if opts && opts.attrs
    @genElement "button", attrs, =>
      @genElement "i", class: "fa fa-#{iconName}"