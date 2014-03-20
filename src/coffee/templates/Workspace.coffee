# @depend Templates.coffee
ATemplate.canvasContainer = Handlebars.compile """
<div id="aw-canvas-container">
  <div id="awcc-outline-text"></div>
  <div id="awcc-outline"></div>
</div>
"""

ATemplate.workspaceScreenSize = """
<div class="input_group">
  <label>Current size: </label>
  <input type="text" value="{{currentSize}}" disabled="disabled" />
</div>
<br />
<div class="input_group">
  <label for="{{cSize}}">Custom Size: </label>
  <input name="{{cSize}}" type="text" value="{{currentSize}}"
    placeholder="WidthxHeight" />
</div>

<div class="input_group">
  <label for="{{pSize}}">Preset Size: </label>
  <select name="{{pSize}}">
    <optgroup label="Android 120 ldpi">
      <option value="240_320">240x320</option>
      <option value="240_400">240x400</option>
      <option value="240_432">240x432</option>
      <option value="480_800">480x800</option>
      <option value="480_854">480x854</option>
      <option value="1024_600">1024x600</option>
    </optgroup>

    <optgroup label="Android 160 mdpi">
      <option value="320_480">320x480</option>
      <option value="480_800">480x800</option>
      <option value="480_854">480x854</option>
      <option value="600_1024">600x1024</option>
      <option value="1280_800">1280x800</option>
      <option value="1024_768">1024x768</option>
      <option value="1280_768">1280x768</option>
    </optgroup>

    <optgroup label="Android 240 hdpi">
      <option value="480_640">480x640</option>
      <option value="480_800">480x800</option>
      <option value="480_854">480x854</option>
      <option value="600_1024">600x1024</option>
      <option value="1536_1152">1536x1152</option>
      <option value="1920_1152">1920x1152</option>
      <option value="1920_1200">1920x1200</option>
    </optgroup>

    <optgroup label="Android 320 xhdpi">
      <option value="640_960">640x960</option>
      <option value="2048_1536">2048x1536</option>
      <option value="2560_1536">2560x1536</option>
      <option value="2560_1600">2560x1600</option>
    </optgroup>

    <optgroup label="iOS iPad & iPad Mini">
      <option value="1024_768">1024x768</option>
      <option value="2048_1536">2048x1536</option>
    </optgroup>

    <optgroup label="iPhone 5, 5s, 4, 4s">
      <option value="1136_640">1136x640</option>
      <option value="960_640">960x640</option>
      <option value="480_320">480x320</option>
    </optgroup>
  </select>
</div>

<div class="input_group">
  <label for="{{pOrie}}">Orientation: </label>
  <div class="radio">
    <input type="radio" name="{{pOrie}}" value="land" {{chL}} /> Landscape
    <input type="radio" name="{{pOrie}}" value="port" {{chP}} /> Portrait
  </div>
</div>

<div class="input_group">
  <label for="{{curScale}}">Scale: </label>
  <input class="wsmall" type="number" name="{{curScale}}"
    value="{{pScale}}" />
</div>
"""

ATemplate.workspaceBackgroundColor = Handlebars.compile """
<div class="input_group">
  <label for="{{ hex }}">Hex: </label>
  <input name="{{ hex }}" type="text" value="\#{{ hexstr }}"></input>
<div>

<br />
<p class="tcenter">Or...</p>
<br />

<div class="input_group">
  <label for="{{r}}">R: </label>
  <input name="{{r}}" type="text" value="{{colorRed}}"></input>
<div>

<div class="input_group">
  <label for="{{g}}">G: </label>
  <input name="{{g}}" type="text" value="{{colorGreen}}"></input>
<div>

<div class="input_group">
  <label for="{{b}}">B: </label>
  <input name="{{b}}" type="text" value="{{colorBlue}}"></input>
<div>

<div id="{{preview}}" class="bg-color-preview" style="{{pInitial}}"></div>

"""