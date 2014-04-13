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
  # Randomly generates a UUID
  # @return [String] id
  ###
  uID: ->
    ##
    # http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript
    'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
      r = Math.random() * 16 | 0
      v = r
      v = r & 0x3 |0x8 if c == "y"
      v.toString 16

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