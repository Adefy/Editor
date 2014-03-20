# @depend Templates.coffee
ATemplate.objectProperties = Handlebars.compile """
<h1><i class="fa fa-fw fa-cog"></i>Basic</h1>
<dl><dt>Width</dt><dd>{{ basic.width }}</dd></dl>
<dl><dt>Height</dt><dd>{{ basic.height }}</dd></dl>
<dl><dt>Opacity</dt><dd>{{ basic.opacity }}</dd></dl>
<dl><dt>Rotation</dt><dd>{{ basic.rotation }}</dd></dl>

<h1><i class="fa fa-fw fa-arrows"></i>Position</h1>
<dl class="half"><dt>X</dt><dd>{{ position.x }}</dd></dl>
<dl class="half"><dt>Y</dt><dd>{{ position.y }}</dd></dl>

<h1><i class="fa fa-fw fa-adjust"></i>Color</h1>
<dl class="third"><dt>R</dt><dd>{{ color.r }}</dd></dl>
<dl class="third"><dt>G</dt><dd>{{ color.g }}</dd></dl>
<dl class="third"><dt>B</dt><dd>{{ color.b }}</dd></dl>

<h1><i class="fa fa-fw fa-anchor"></i>Physics</h1>
<dl><dt>Mass</dt><dd>{{ physics.mass }}</dd></dl>
<dl><dt>Elasticity</dt><dd>{{ physics.elasticity }}</dd></dl>
<dl><dt>Friction</dt><dd>{{ physics.friction }}</dd></dl>
"""