# This class implements some helper methods for function param enforcement
# It simply serves to standardize error messages for missing/incomplete
# parameters, and set them to default values if such values are provided.
#
# Since it can be used in every method of every class, it is created static
# and attached to the window object as 'param'
class AUtilParam

  @required: (p) ->
    if p == undefined then throw new error "Required argument missing!"
    p

  @optional: (p, def) ->
    if p == undefined then p = def
    p

window.param = AUtilParam
