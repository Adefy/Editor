# The point of this is to gather all local storage operations in a central
# location, so we can potentially persist them to a server in the future.

# We stringify all values going into storage, and parse them on their way out,
# since HTML5 localStorage is limited to string key/value pairs. (It's nice to
# retain type information)
define

  set: (key, value) ->
    window.localStorage.setItem key, JSON.stringify value

  get: (key) ->
    try
      JSON.parse window.localStorage.getItem(key)
    catch e
      return null
