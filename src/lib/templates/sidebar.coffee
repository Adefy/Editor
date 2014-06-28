define ->

  ###
  # @property [Object] data Sidebar actor data
  ###
  Handlebars.compile """
  <header>
    <div class="sb-actor-name">Rectangle 145</div>
  </header>
  <section>
    <div class="sb-controls">
      <ul class="sb-controls-left">
        <li class="sb-control">
          <i>x</i>
          <input type="number" value="1500" />
        </li>
        <li class="sb-control">
          <i>y</i>
          <input type="number" value="130" />
        </li>
      </ul>

      <ul class="sb-controls-right">
        <li class="sb-control">
          <i class="fa fa-arrows-v"></i>
          <input type="number" value="1500" />
        </li>
        <li class="sb-control">
          <i class="fa fa-arrows-h"></i>
          <input type="number" value="130" />
        </li>
        <li class="sb-control">
          <i class="fa fa-rotate-left"></i>
          <input type="number" value="130" />
        </li>
      </ul>
    </div>

    <div class="sb-appearance">
      <div class="sb-ap-sample color"></div>
      <a class="sb-ap-dialogue" href="javascript:void(0)">Appearance...</a>
    </div>

    <div class="sb-opacity">
      <div class="sb-op-slider">
        <input type="range" min="0" max="1" value="1" />
      </div>
      <label class="sb-op-label">Opacity</label>
      <input class="sb-op-input" type="number" min="0" max="1" value="1" />
    </div>

    <ul class="sb-dialogues">
      <li>
        <input type="checkbox" name="physics" />
        <a href="javascript:void(0)">Physics...</a>
      </li>
      <li>
        <input type="checkbox" name="spawning" />
        <a href="javascript:void(0)">Spawning...</a>
      </li>
    </ul>
  </section>
  """
