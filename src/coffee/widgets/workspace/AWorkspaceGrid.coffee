class AWorkspaceGrid
	GRID_STEP = 50	


	constructor: (@workspace)->
		@_state = 'hidden'
		@_gridLines = []

	toggleVisibility: ->
		if @_isVisible() 
			@_hideGrid()
			newState = 'hidden'
		else
			@_showGrid()
			newState = 'visible'
		@_changeState newState			

	_hideGrid: ->
		$.each(@_gridLines, (index, lineRectangle) -> lineRectangle.destroy())
		@_gridLines = []

	_showGrid: ->
		@_clearWorkspace()
		gridColor = new AJSColor3(0, 0, 0)		
		startHorizontalPosition = $('#awcc-outline').offset().left + GRID_STEP
		console.log @workspace._cHeight
		console.log @workspace._cWidth
		rightHorizontalEnd = startHorizontalPosition + 800 - GRID_STEP 
		leftVerticalStart = $('#awcc-outline').offset().top + $('#awcc-outline').height() / 2
		height =  $('#awcc-outline').height()
		while startHorizontalPosition <= rightHorizontalEnd
			ret = @workspace.domToGL(startHorizontalPosition, leftVerticalStart) 
			currentPosition = new AJSVector2(ret.x, ret.y)
			newGridLine = new AJSRectangle(
				w: 1, 
				h: height, 
				mass: false, 
				friction: 0, 
				elasticity: false, 
				color: gridColor, 
				position: currentPosition, 
				rotation: 0, 
				psyx: false
			)
			@_gridLines.push newGridLine
			startHorizontalPosition += GRID_STEP

		startVerticalPosition = $('#awcc-outline').offset().top
		leftSide = $('#awcc-outline').offset().left + $('#awcc-outline').width() / 2 
		topHeight = $('#awcc-outline').height() + startVerticalPosition
		width = $('#awcc-outline').width()

		while startVerticalPosition <= topHeight
			ret = @workspace.domToGL(leftSide, startVerticalPosition) 
			currentPosition = new AJSVector2(ret.x, ret.y)
			newGridLine = new AJSRectangle(
				w: width, 
				h: 1, 
				mass: false, 
				friction: 0, 
				elasticity: false, 
				color: gridColor, 
				position: currentPosition, 
				rotation: 0, 
				psyx: false
			)
			@_gridLines.push newGridLine
			startVerticalPosition += GRID_STEP
		@_restoreWorkspace()	

	_isVisible: ->
		@_state == 'visible'

	_changeState: (newState)->
		@_state = newState

	_clearWorkspace: ->
		@_savedState = window.adefy_editor._serialize()
		while(@workspace.actorObjects.length > 0)
			@workspace.actorObjects.pop().delete()
		_timeline = AWidgetTimeline.getMe()	
		while(_timeline._actors.length > 0)	
			_timeline._actors.pop().delete()
		_timeline.render()		
		

	_restoreWorkspace: ->		
		window.adefy_editor._deserialize(@_savedState)