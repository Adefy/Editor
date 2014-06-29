define ->

  ###
  # @property [Object] data Sidebar actor data
  ###
  Handlebars.compile """
  <div class="sb-primary">
    <header>
      <div class="sb-title">
        {{#if actorName}}
        {{actorName}}
        {{else}}
        Select an actor...
        {{/if}}
      </div>
    </header>

    <section>
    {{#if actorName}}

      <div class="sb-controls">
        <ul class="sb-controls-left">
          <li class="sb-control" data-id="position-x">
            <i>x</i>
            <input type="number" value="1500" />
          </li>
          <li class="sb-control" data-id="position-y">
            <i>y</i>
            <input type="number" value="130" />
          </li>
          <li class="sb-control" data-id="rotation">
            <i class="fa fa-rotate-left"></i>
            <input type="number" value="130" />
          </li>
        </ul>

        <ul class="sb-controls-right">
          {{#if controls}}
          {{#each controls}}
          <li class="sb-control" data-id="{{name}}">
            <i class="fa {{icon}}"></i>
            <input type="number" value="{{value}}" min="{{min}}" max="{{max}}" />
          </li>
          {{/each}}
          {{/if}}
        </ul>
      </div>

      <div class="sb-appearance">
        <div class="sb-ap-sample"></div>
        <a class="sb-ap-dialogue" href="javascript:void(0)">Appearance...</a>
      </div>

      <div class="sb-opacity">
        <div class="sb-op-slider">
          <input type="range" min="0" max="100" value="100" />
        </div>
        <label class="sb-op-label">Opacity</label>
        <input class="sb-op-input" type="number" min="0" max="100" />
      </div>

      <ul class="sb-dialogues">
        <li data-id="physics">
          <input type="checkbox" name="physics" />
          <a href="javascript:void(0)">Physics...</a>
        </li>
        <li data-id="spawn">
          <input type="checkbox" name="spawning" />
          <a href="javascript:void(0)">Spawning...</a>
        </li>
      </ul>

    {{/if}}
    </section>
  </div>

  {{#if actorName}}
  <div class="sb-secondary sb-seco-physics">
    <header>
      <div class="sb-title">Physics settings...</div>
    </header>
    <section>
      <div class="sb-controls">
        <ul class="sb-controls-left">
          <li class="sb-control" data-id="mass">
            <label>Mass</label>
            <input type="number" value="20" min="0" />
          </li>
          <li class="sb-control" data-id="elasticity">
            <label>Elasticity</label>
            <input type="number" value="10" min="0" max="100" />
            <label class="suffix">%</label>
          </li>
          <li class="sb-control" data-id="friction">
            <label>Friction</label>
            <input type="number" value="70" min="0" max="100" />
            <label class="suffix">%</label>
          </li>
        </ul>

        <ul class="sb-controls-right">
          <li class="sb-control" data-id="mass">
            <input type="checkbox" name="physics-static" /> Static
          </li>
        </ul>
      </div>

      <div class="sb-commit">
        <button class="sb-cancel">Cancel</button>
        <button class="sb-apply">Apply</button>
      </div>
    </section>
  </div>

  <div class="sb-secondary sb-seco-spawn">
    <header>
      <div class="sb-title">Spawning settings...</div>
    </header>
    <section>
      <div class="sb-controls">
        <ul class="sb-controls-wide">
          <li class="sb-control" data-id="frequency">
            <label>Spawn a particle every</label>
            <input type="number" value="150" min="0" />
            <label class="suffix">ms</label>
          </li>
          <li class="sb-control" data-id="lifetime">
            <label>Each particle lives</label>
            <input type="number" value="7000" min="0" />
            <label class="suffix">ms</label>
          </li>
          <li class="sb-control" data-id="limit">
            <label>Display at most</label>
            <input type="number" value="500" min="0" />
            <label class="suffix">particles</label>
          </li>
        </ul>
      </div>

      <div class="sb-controls">
        <label>Spawning area</label>

        <ul class="sb-controls-left">
          <li class="sb-control" data-id="area-width">
            <i class="fa fa-arrows-h"></i>
            <input type="number" value="100" min="0" />
          </li>
        </ul>

        <ul class="sb-controls-right">
          <li class="sb-control" data-id="area-height">
            <i class="fa fa-arrows-v"></i>
            <input type="number" value="100" min="0" />
          </li>
        </ul>
      </div>

      <div class="sb-controls">
        <label>Initial velocity</label>

        <ul class="sb-controls-left">
          <li class="sb-control small" data-id="vel-x-min">
            <i>x min</i>
            <input type="number" value="2" min="0" />
          </li>
          <li class="sb-control small" data-id="vel-y-min">
            <i>y min</i>
            <input type="number" value="7" min="0" />
          </li>
        </ul>

        <ul class="sb-controls-right">
          <li class="sb-control small" data-id="vel-x-max">
            <i>max</i>
            <input type="number" value="9" min="0" />
          </li>
          <li class="sb-control small" data-id="vel-y-max">
            <i>max</i>
            <input type="number" value="15" min="0" />
          </li>
        </ul>
      </div>

      <div class="sb-commit">
        <button class="sb-cancel">Cancel</button>
        <button class="sb-apply">Apply</button>
      </div>
    </section>
  </div>
  {{/if}}
  """
