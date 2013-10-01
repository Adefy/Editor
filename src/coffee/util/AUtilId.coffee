##
## Copyright © 2013 Spectrum IT Solutions Gmbh - All Rights Reserved
##

# Tiny utility to provide unique ids from anywhere
window.__nextID = 0

# Returns the next unique id
#
# @return [String] id
window.nextId = -> "#{window.__nextID++}"

# Returns a unique id with the specified prefix
#
# @param [String] prefix
# @return [String] id
window.prefId = (pref) -> "#{pref}-#{window.__nextID++}"
