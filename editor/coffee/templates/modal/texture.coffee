define ->

  Handlebars.compile """
  <header class="origin-top">
    <button class="tl-upload">Upload Texture...</button>
  </header>

  <section>

    {{#if textures}}
    <ul class="tl-list">

      {{#each textures}}
      <li class="tl-entry" data-id="{{uid}}">
        <div class="tl-entry-img">
          <div style="background-image: url('{{url}}')"></div>
        </div>
        <span class="tl-entry-filename">{{name}}</span>
        <span class="tl-entry-dimensions">-</span>
        <span class="tl-entry-filesize">{{size}}</span>
      </li>
      {{/each}}

    </ul>
    {{else}}
    <ul class="tl-empty">
      <span>Your texture library is empty</span>
      <a href="javascript:void(0)">
        <div>
          <i class="fa fa-upload"></i>
          <span>Upload your first texture</span>
        </div>
      </a>
    <ul>
    {{/if}}

  </section>
  """
