define ->

  Handlebars.compile """
  <header class="origin-top">
    <button class="tl-upload">Upload Texture...</button>
  </header>

  <section>

    {{#if textures}}
    <ul class="tl-list">

      <li class="tl-entry">
        <div class="tl-entry-img">
          <div style="background-image: url(http://lorempixel.com/256/256)"></div>
        </div>
        <span class="tl-entry-filename">kitten_1.png</span>
        <span class="tl-entry-dimensions">200 x 300 px</span>
        <span class="tl-entry-filesize">234KB</span>
      </li>

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
