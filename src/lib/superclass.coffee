define (require) ->

  moduleKeywords = ["included", "extended"]

  ##
  # http://stackoverflow.com/questions/9064935/extending-multiple-classes-in-coffee-script
  class EditorSuperClass

    @include: (obj) ->
      throw("include(obj) requires obj") unless obj

      for key, value of obj.prototype when key not in moduleKeywords
          @::[key] = value

      included = obj.included
      included.apply(this) if included

      @
