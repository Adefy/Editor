define ->

  ###
  # @property [Object] basic Basic properties
  #   @property [Number] width
  #   @property [Number] height
  #   @property [Number] opacity
  #   @property [Number] rotation
  # @property [Object] position Position properties
  #   @property [Number] x
  #   @property [Number] y
  # @property [Object] color Color properties
  #   @property [Number] r
  #   @property [Number] g
  #   @property [Number] b
  # @property [Object] psxy Physics properties
  #   @property [Number] mass
  #   @property [Number] elasticity
  #   @property [Number] friction
  ###
  Handlebars.compile """
    <h1><i class="fa fa-fw fa-cog"></i>Basic</h1>
    <div id="basic">
      <dl><dt>Width</dt><dd id="width">{{ basic.width }}</dd></dl>
      <dl><dt>Height</dt><dd id="height">{{ basic.height }}</dd></dl>
      <dl><dt>Opacity</dt><dd id="opacity">{{ basic.opacity }}</dd></dl>
      <dl><dt>Rotation</dt><dd id="rotation">{{ basic.rotation }}</dd></dl>
    </div>

    <h1><i class="fa fa-fw fa-arrows"></i>Position</h1>
    <div id="position">
      <dl class="half"><dt>X</dt><dd id="x">{{ position.x }}</dd></dl>
      <dl class="half"><dt>Y</dt><dd id="y">{{ position.y }}</dd></dl>
    </div>

    <h1><i class="fa fa-fw fa-adjust"></i>Color</h1>
    <div id="color">
      <dl class="third"><dt>R</dt><dd id="r">{{ color.r }}</dd></dl>
      <dl class="third"><dt>G</dt><dd id="g">{{ color.g }}</dd></dl>
      <dl class="third"><dt>B</dt><dd id="b">{{ color.b }}</dd></dl>
    </div>

    <h1><i class="fa fa-fw fa-anchor"></i>Physics</h1>
    <div id="psyx">
      <dl><dt>Mass</dt><dd id="mass">{{ psyx.mass }}</dd></dl>
      <dl><dt>Elasticity</dt><dd id="elasticity">{{ psyx.elasticity }}</dd></dl>
      <dl><dt>Friction</dt><dd id="friction">{{ psyx.friction }}</dd></dl>
    </div>
  """
