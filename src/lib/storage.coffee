# The point of this is to gather all local storage operations in a central
# location, so we can potentially persist them to a server in the future.

# For the time being, this maps directly to the localStorage API
define
  set: (key, value) ->
    window.localStorage.setItem key, value

  get: (key) ->
    window.localStorage.getItem key
