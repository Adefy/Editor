define ->

  ###
  ###
  Handlebars.compile """
    <div>
      <h1>Adefy Editor</h1>
      <h2>Change Log</h2>
      <ul>
        {{#each changes}}
        <li>
          <dl>
            <dt>Date</dt>
            <dd>{{date}}</dd>
            <dt>Version</dt>
            <dd>{{version}}</dd>
            <ul>
            {{#each body}}
              <li>{{this}}</li>
            {{/each}}
            </ul>
          </dl>
        </li>
        {{/each}}
      </ul>
    </div>
  """
