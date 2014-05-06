define (require) ->

  priorityCheck =
    optional: (key, a, def) ->
      if a == null || a == undefined
        return def()
      a

    required: (key, a, d) ->
      if a == null || a == undefined
        throw new Error "invalid #{key}, #{a}"

      return a

  ###
  # @param [Object] ref  reference properties to use for validation
  # @param [Object] options  properties to validate
  ###
  check = (ref, options) ->
    result = {}

    for key, info of ref
      prio = info.priority
      value = priorityCheck[prio||"optional"](key, options[key], info.def)

      if info.type == "composite"
        value = check info.properties, value
      else
        # type validation
        if info.type
          unless typeof(value) == info.type
            throw new Error "#{key}:{#{value}} of wrong type (expected #{info.type})"

        # validation
        if v = info.validate
          throw new Error "#{key}:{#{value}} has failed validation" unless v(value)

      result[key] = value

    result

  check