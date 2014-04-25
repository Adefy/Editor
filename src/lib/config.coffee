###
# AdefyEditor config
###
define
  debug:
    event_log:  false
    render_log: false

  # enable and disable certain features
  use:
    spawner: true

  # html element ids
  id:
    are_canvas: "are-canvas"

  # css selectors
  selector:
    header:  "header"
    content: "section.main"
    footer:  "footer"

  # ui.icons
  icon:
    # ui.toggle
    toggle_down:  "fa-toggle-down"
    toggle_left:  "fa-toggle-left"
    toggle_right: "fa-toggle-right"
    toggle_up:    "fa-toggle-up"

    # handle.properties
    property_default:   "fa-cog"
    property_basic:     "fa-cog"
    property_color:     "fa-adjust"
    property_layer:     "fa-tasks"
    property_physics:   "fa-anchor"
    property_position:  "fa-arrows"
    ## particle system
    property_particles: "fa-star"
    property_spawn:     "fa-dot-circle-o"

  # number precision
  precision:
    # animation rounding
    animation: 4
    # precision used for properties
    base: 0                 # TriangleActor.base
    color: 0                # Actor.color
    height: 0               # TriangleActor.height and RectangleActor.height
    layer: 1                # Actor.layer and Actor.physicsLayer
    opacity: 2              # Actor.opacity
    physics_elasticity: 6   # Actor.physics.elasticity
    physics_friction: 6     # Actor.physics.friction
    physics_mass: 0         # Actor.physics.mass
    position: 0             # Actor.position.x and Actor.position.y
    radius: 0               # CircleActor.radius
    rotation: 0             # Actor.rotation
    sides: 0                # PolygonActor.sides
    width: 0                # RectangleActor.width

  ##
  locale:
    duplicate: "Duplicate"
    copy:      "Copy"
    cut:       "Cut"
    paste:     "Paste"

    title:
      create: "Create"

    label:
      create_menu_item: "Create +"
      texture_modal:    "Texture ..."
      physics_modal:    "Physics ..."
      ##
      actor_rectangle:  "Rectangle Actor"
      actor_polygon:    "Polygon Actor"
      actor_circle:     "Circle Actor"
      actor_triangle:   "Triangle Actor"

    ctx:
      base_actor:
        make_spawner: "Make Spawner"

      spawner:
        configure: "Configure..."
        spawn: "Spawn"
