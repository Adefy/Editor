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
      <dl><dt>Width</dt><dd id="width" class="drag_mod">{{ basic.width }}</dd></dl>
      <dl><dt>Height</dt><dd id="height" class="drag_mod">{{ basic.height }}</dd></dl>
      <dl><dt>Opacity</dt><dd id="opacity" class="drag_mod">{{ basic.opacity }}</dd></dl>
      <dl><dt>Rotation</dt><dd id="rotation" class="drag_mod">{{ basic.rotation }}</dd></dl>
    </div>

    <h1><i class="fa fa-fw fa-arrows"></i>Position</h1>
    <div id="position">
      <dl class="half"><dt>X</dt><dd id="x" class="drag_mod">{{ position.x }}</dd></dl>
      <dl class="half"><dt>Y</dt><dd id="y" class="drag_mod">{{ position.y }}</dd></dl>
    </div>

    <h1><i class="fa fa-fw fa-adjust"></i>Color</h1>
    <div id="color">
      <dl class="third"><dt>R</dt><dd id="r" class="drag_mod">{{ color.r }}</dd></dl>
      <dl class="third"><dt>G</dt><dd id="g" class="drag_mod">{{ color.g }}</dd></dl>
      <dl class="third"><dt>B</dt><dd id="b" class="drag_mod">{{ color.b }}</dd></dl>
    </div>

    <h1><i class="fa fa-fw fa-anchor"></i>Physics</h1>
    <div id="psyx">
      <dl><dt>Mass</dt><dd id="mass" class="drag_mod">{{ psyx.mass }}</dd></dl>
      <dl><dt>Elasticity</dt><dd id="elasticity" class="drag_mod">{{ psyx.elasticity }}</dd></dl>
      <dl><dt>Friction</dt><dd id="friction" class="drag_mod">{{ psyx.friction }}</dd></dl>
    </div>
  """
