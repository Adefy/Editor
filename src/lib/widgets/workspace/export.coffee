define ->

  ###
  # This handles the exporting of our workspace, and generates AJS source
  # accordingly. It creates a package.json, and packages all assets
  #
  # There are two modes of export, one that exports final ads for our server
  # and ad preview, and another that exports standalone WebGL ads (deps included)
  ###
  class Export

    ###
    # Initializes, and calls @update(), allowing for export data to be refreshed
    # at will. To actually generate an export, call one of the export functions
    ###
    constructor: ->

      # Set to true in update, provides a safety net in case we ever remove the
      # @update() call from our constructor, and attempt to export without
      # manually calling it.
      @_readyForExport = false

      # Update!
      @update()

    ###
    # Collects data from the environment for export. Exports are not possible
    # until this method is called.
    #
    # (called in the constructor, we are so thoughtful)
    ###
    update: ->

      # Lots of important stuff

    ###
    # Export a proper ad package, ready for preview or to be sent to our servers
    # Note that an ad exported using this method will not be directly served
    # by Adefy, as it lacks signing info!
    ###
    exportAJS: ->

      if not @_readyForExport
        throw new Error "Export not updated, can't export!"

    ###
    # Export an ad bundle, including the results of exportAJS along with an
    # index.html and all associated files necessary to view the ad in a browser
    # that supports WebGL. Use this to pass awesome ads around to your homies.
    ###
    exportBundle: ->

      if not @_readyForExport
        throw new Error "Export not updated, can't export!"
