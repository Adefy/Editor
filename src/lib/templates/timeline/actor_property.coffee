define ->

  ###
  # Actor Property
  # @property [String] id
  # @property [String] title
  # @property [String] value
  ###
  Handlebars.compile """
    <div id="{{ id }}" class="row property">
      <div class="live">
        <button><i class="fa fa-fw fa-clock-o"></i></button>
      </div>
      <div class="graph">
        <button><i class="fa fa-fw fa-cog"></i></button>
      </div>
      <div class="title">{{ title }}</div>
      <div class="value">{{ value }}</div>
    </div>
  """
