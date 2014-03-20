# @depend Templates.coffee

ATemplate.statusbar = Handlebars.compile """
Version {{ version }}<div class="save done"><i class="fa fa-fw fa-circle"></i></div>
"""