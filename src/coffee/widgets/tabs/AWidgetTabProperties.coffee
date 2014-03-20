
# @depend AWidgetTab.coffee

class AWidgetTabProperties extends AWidgetTab

  constructor: (parent) ->
    @_actor = null
    super parent

  setActor: (actor) ->
    @_actor = actor

  render: ->
    width = "--px"
    height = "--px"
    opacity = "-.-"
    rotation = "-.-°"

    x = "-.-"
    y = "-.-"

    r = "-.-"
    g = "-.-"
    b = "-.-"

    mass = "--"
    elasticity = "-.-"
    friction = "-.-"

    if @_actor
      width = "#{@_actor.width}px"
      height = "#{@_actor.height}px"
      opacity = "#{@_actor.opacity}"
      rotation = "#{@_actor.rotation}°"

      x = "#{@_actor.x}"
      y = "#{@_actor.y}"

      r = "#{@_actor.color.r}"
      g = "#{@_actor.color.g}"
      b = "#{@_actor.color.b}"

      mass = "#{@_actor.mass}"
      elasticity = "#{@_actor.elasticity}"
      friction = "#{@_actor.friction}"

    ## Basic
    _html = @genElement "h1", {}, =>
      @genElement("i", class: "fa fa-fw fa-cog") + "Basic"
    ## Width
    _html+= @genElement "dl", {}, =>
      @genElement("dt", {}, => "Width") +
      @genElement("dd", {}, => "#{width}")
    ## Height
    _html+= @genElement "dl", {}, =>
      @genElement("dt", {}, => "Height") +
      @genElement("dd", {}, => "#{height}")
    ## Opacity
    _html+= @genElement "dl", {}, =>
      @genElement("dt", {}, => "Opacity") +
      @genElement("dd", {}, => "#{opacity}")
    ## Rotation
    _html+= @genElement "dl", {}, =>
      @genElement("dt", {}, => "Rotation") +
      @genElement("dd", {}, => "#{rotation}")

    ## Position
    _html+= @genElement "h1", {}, =>
      @genElement("i", class: "fa fa-fw fa-arrows") + "Position"
    ## X
    _html+= @genElement "dl", class: "half", =>
      @genElement("dt", {}, => "X") +
      @genElement("dd", {}, => "#{x}")
    ## Y
    _html+= @genElement "dl", class: "half", =>
      @genElement("dt", {}, => "Y") +
      @genElement("dd", {}, => "#{y}")

    ## Color
    _html+= @genElement "h1", {}, =>
      @genElement("i", class: "fa fa-fw fa-adjust") + "Color"
    ## R
    _html+= @genElement "dl", class: "third", =>
      @genElement("dt", {}, => "R") +
      @genElement("dd", {}, => "#{r}")
    ## G
    _html+= @genElement "dl", class: "third", =>
      @genElement("dt", {}, => "G") +
      @genElement("dd", {}, => "#{g}")
    ## B
    _html+= @genElement "dl", class: "third", =>
      @genElement("dt", {}, => "B") +
      @genElement("dd", {}, => "#{b}")

    ## Physics
    _html+= @genElement "h1", {}, =>
      @genElement("i", class: "fa fa-fw fa-anchor") + "Physics"
    ## R
    _html+= @genElement "dl", {}, =>
      @genElement("dt", {}, => "Mass") +
      @genElement("dd", {}, => "#{mass}")
    ## G
    _html+= @genElement "dl", {}, =>
      @genElement("dt", {}, => "Elasticity") +
      @genElement("dd", {}, => "#{elasticity}")
    ## B
    _html+= @genElement "dl", {}, =>
      @genElement("dt", {}, => "Friction") +
      @genElement("dd", {}, => "#{friction}")

    _html