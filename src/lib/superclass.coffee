define (require) ->

  moduleKeywords = ["included", "extended"]

  ##
  # http://stackoverflow.com/questions/9064935/extending-multiple-classes-in-coffee-script
  # http://arcturo.github.io/library/coffeescript/03_classes.html
  class EditorSuperClass

    @include: (obj) ->
      throw("include(obj) requires obj") unless obj

      for key, value of obj.prototype when key not in moduleKeywords
          @::[key] = value

      obj.included?.apply @
      @
