###
# AdefyEditor config, read individual sections for details
###
define

  ###
  # Debug parameters; controls various log levels
  ###
  debug:
    event_log:     false
    render_log:    false
    are_log_level: 3

  ###
  # HTML element IDs
  ###
  id:
    are_canvas: "are-canvas"

  ###
  # CSS selectors
  ###
  selector:
    header:  "header"
    content: "section.main"
    footer:  "footer"

  ###
  # UI icon classes
  ###
  icon:

    toggle_down:        "fa-toggle-down"
    toggle_left:        "fa-toggle-left"
    toggle_right:       "fa-toggle-right"
    toggle_up:          "fa-toggle-up"

    property_default:   "fa-cog"
    property_basic:     "fa-cog"
    property_color:     "fa-adjust"
    property_layer:     "fa-tasks"
    property_physics:   "fa-anchor"
    property_position:  "fa-arrows"
    property_particles: "fa-star"
    property_spawn:     "fa-dot-circle-o"

  ###
  # Number precision; values specify the number of digits values are rounded to
  ###
  precision:

    # Animation rounding
    base: 4                 # Base rounding, used by default for all actor props
    color: 0                # Actor.color
    height: 0               # RectangleActor.height
    layer: 1                # Actor.layer
    physicsLayer: 0         # Actor.physicsLayer
    opacity: 2              # Actor.opacity
    physics_elasticity: 6   # Actor.physics.elasticity
    physics_friction: 6     # Actor.physics.friction
    physics_mass: 0         # Actor.physics.mass
    position: 0             # Actor.position.x and Actor.position.y
    radius: 0               # CircleActor.radius
    rotation: 0             # Actor.rotation
    sides: 0                # PolygonActor.sides
    texture_repeat: 2       # BaseActor.textureRepeat
    width: 0                # RectangleActor.width

  ###
  # This section defines interface strings, and is expected to be replaced on
  # load for locales other than englines. The strings must use proper
  # capitalisation, and should not include any form of ending punctuation.
  ###
  strings:
    duplicate:            "Duplicate"
    copy:                 "Copy"
    cut:                  "Cut"
    paste:                "Paste"
    configure:            "Configure"

    texture:              "Texture"
    texture_repeat:       "Texture Repeat"
    physics:              "Physics"

    create_actor:         "Create Actor"
    actor_rectangle:      "Rectangle Actor"
    actor_polygon:        "Polygon Actor"
    actor_circle:         "Circle Actor"

    make_spawner:         "Make Spawner"
    spawn:                "Spawn"
