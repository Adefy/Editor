# Tiny utility to provide unique ids from anywhere
define
  __nextID: 0

  ###
  # Returns the next unique id
  #
  # @return [String] id
  ###
  nextId: -> "#{@__nextID++}"

  ###
  # Returns a unique id with the specified prefix
  #
  # @param [String] prefix
  # @return [String] id
  ###
  prefId: (pref) -> "#{pref}-#{@__nextID++}"
