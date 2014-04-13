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
  prefId: (prefix) -> "#{prefix}-#{@__nextID++}"

  ###
  # Returns both a prefix id and Number
  # @param [String] prefix
  # @return [Object]
  #   @property [Number] id
  #   @property [String] prefix
  ###
  objId: (prefix) ->
    id = @__nextID++
    {
      id: id
      prefix: "#{prefix}-#{id}"
    }