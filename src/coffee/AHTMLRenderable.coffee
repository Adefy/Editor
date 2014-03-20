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
  # @param [Object] opts
  #   @option [Boolean] fixedWidth
  #   @option [Object] buttonAttrs
  #   @option [Object] iconAttrs
  # @return [String] html
  ###
  genButtonIcon: (iconName, opts) ->
    buttonAttrs = {}
    buttonAttrs = opts.buttonAttrs if opts && opts.buttonAttrs
    iconAttrs = {}
    iconAttrs = opts.iconAttrs if opts && opts.iconAttrs
    iconKlass = if opts && opts.fixedWidth
      "fa fa-fw fa-#{iconName}"
    else
      "fa fa-#{iconName}"

    iconAttrs["class"] = "" unless iconAttrs["class"]
    iconAttrs["class"] += iconKlass

    @genElement "button", buttonAttrs, =>
      @genElement "i", iconAttrs