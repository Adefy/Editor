##
## Copyright © 2014 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# @depend Templates.coffee

###
# @property [String] version The current Adefy Editor version
###
ATemplate.statusbar = Handlebars.compile """
Version {{ version }}<div class="save done"><i class="fa fa-fw fa-circle"></i></div>
"""