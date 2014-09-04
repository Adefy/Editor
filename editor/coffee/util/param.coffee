define ->

  # This class implements some helper methods for function param enforcement
  # It simply serves to standardize error messages for missing/incomplete
  # parameters, and set them to default values if such values are provided.
  #
  # Since it can be used in every method of every class, it is created static
  # and attached to the window object as 'param'
  class AUtilParam

    # Defines an argument as required. Ensures it is defined and valid
    #
    # @param [Object] p parameter to check
    # @param [Array] valid optional array of valid values the param can have
    # @param [Boolean] canBeNull true if the value can be null
    # @return [Object] p
    @required: (p, valid, canBeNull) ->

      if p == null and canBeNull != true
        throw new Error "Required argument can not be null!"
      if p == undefined
        throw new Error "Required argument missing!"

      # Check for validity if required
      if valid instanceof Array
        if valid.length > 0
          isValid = false
          for v in valid
            if p == v
              isValid = true
              break
          if not isValid
            throw new Error "Required argument is not of a valid value!"

      # Ship
      p

    # Defines an argument as optional. Sets a default value if it is not
    # supplied, and ensures validity (post-default application)
    #
    # @param [Object] p parameter to check
    # @param [Object] def default value to use if necessary
    # @param [Array] valid optional array of valid values the param can have
    # @param [Boolean] canBeNull true if the value can be null
    # @return [Object] p
    @optional: (p, def, valid, canBeNull) ->

      if p == null and canBeNull != true then p = undefined
      if p == undefined then p = def

      # Check for validity if required
      if valid instanceof Array
        if valid.length > 0
          isValid = false
          for v in valid
            if p == v
              isValid = true
              break
          if not isValid
            throw new Error "Required argument is not of a valid value!"

      p
