class AWorkspaceGrid
	GRID_STEP: 50	
	ZOOM_RATE: 1
	# available positions - 'above', 'below'
	GRID_POSITION: 'above' 
	SNAP: false


	constructor: (@workspace)->
		@_state = 'hidden'
		@_gridLines = []
		AWorkspaceGrid._currentInstance = @

	@_getInstance: -> @._currentInstance

	gridStep: -> AWorkspaceGrid._gridStep || @.GRID_STEP	
	zoomRate: -> @.ZOOM_RATE
	gridPosition: -> AWorkspaceGrid._gridPosition || @.GRID_POSITION


	toggleVisibility: ->
		if @_isVisible() 
			@_hideGrid()
			@_stopSpecialMousePointer()
			newState = 'hidden'
		else
			@_showGrid()
			@_startSpecialMousePointer()
			newState = 'visible'
		@_changeState newState			

	_hideGrid: ->
		$.each(@_gridLines, (index, lineRectangle) -> lineRectangle.destroy())
		@_gridLines = []

	_showGrid: ->
		if @_gridBelowAll()
			@_clearWorkspace()
		gridColor = new AJSColor3(0, 0, 0)		
		startHorizontalPosition = $('#awcc-outline').offset().left + @gridStep()
		rightHorizontalEnd = startHorizontalPosition + 800 - @gridStep() 
		leftVerticalStart = $('#awcc-outline').offset().top + $('#awcc-outline').height() / 2
		height =  $('#awcc-outline').height()
		while startHorizontalPosition <= rightHorizontalEnd
			ret = @workspace.domToGL(startHorizontalPosition, leftVerticalStart) 
			currentPosition = new AJSVector2(ret.x, ret.y)
			newGridLine = new AJSRectangle(
				w: 1, 
				h: height, 
				mass: 1.0, 
				friction: 0, 
				elasticity: 1.0, 
				color: gridColor, 
				position: currentPosition, 
				rotation: 0, 
				psyx: false
			)
			@_gridLines.push newGridLine
			startHorizontalPosition += @gridStep()

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
				mass: 1.0, 
				friction: 0, 
				elasticity: 1.0, 
				color: gridColor, 
				position: currentPosition, 
				rotation: 0, 
				psyx: false
			)
			@_gridLines.push newGridLine
			startVerticalPosition += @gridStep()
		if @_gridBelowAll()
			@_restoreWorkspace()	

	_gridBelowAll: -> 
		@gridPosition() == 'below'		

	_gridAboveAll: -> 
		@gridPosition() == 'above'		

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

	@showSetGridSettings: ->
		_html = """
		      	  
		        <div class='input_group'>
		        	<label for="gridPosition">Position:</label>
		        	<select name="gridPosition">
		        		<option value="above" #{@_isSelectedPosition('above')}>Above all elements</option>
		        		<option value="below" #{@_isSelectedPosition('below')}>Below all elements</option>
		        	</select>
		        </div>

				 <div class="input_group">
		 	        <label for="gridStep">Step: </label>
		 	        <select name="gridStep">
		 	            <option value="10" #{@_isSelected(10)}>10</option>
		 	            <option value="25" #{@_isSelected(25)}>25</option>
		 	            <option value="50" #{@_isSelected(50)}>50</option>
		 	            <option value="75" #{@_isSelected(75)}>75</option>
		 	            <option value="100" #{@_isSelected(100)}>100</option>
		 	            <option value="150" #{@_isSelected(150)}>150</option>
		 	            <option value="200" #{@_isSelected(200)}>200</option>
		 	        </select>
		         </div>
		         <div class='input_group'>
		         	<label for='gridSnap'>Snap:</label>
		         	<input name='gridSnap' type='checkbox' value='1' #{@_snapOnSelected()} />
		         </div>

				"""
		new AWidgetModal "Set Grid Settings", _html, false, 
			null
			, null
			, (deltaName, deltaValue, data)=>
				@["_#{deltaName}Change"](deltaValue)
		$('.amtitle').css({'padding-bottom': '5px'})
		$('.aminner').css({'padding-top': '5px'})		
				
	@_isSelected: (step)->
		currentStep = @._gridStep || @._getInstance().GRID_STEP
		if step == currentStep 
			'selected'
		else
			''	

	@_isSelectedPosition: (position)->
		currentPosition = @._gridPosition || @._getInstance().GRID_POSITION
		if position == currentPosition 
			'selected'
		else
			''			

	@_gridPositionChange: (newValue)->
		@_gridPosition = newValue
		@redrawInstance()

	@_gridStepChange: (newValue)->		
		@_gridStep = parseInt(newValue)
		@redrawInstance()

	@_gridSnapChange: (newValue)->
		@_getInstance().SNAP = !@_getInstance.SNAP

	@snapOn: ->
		@_getInstance().SNAP	

	@_snapOnSelected: ->
		if @snapOn
			'selected'	

	@redrawInstance: ->
		_instance = @_getInstance()
		if _instance && _instance._isVisible()
			_instance._hideGrid()
			_instance._showGrid()	

	@gridAboveAll: -> @_gridPosition == 'above'		
	
	_startSpecialMousePointer: -> 
		AMouseTracker.startTracking(@workspace)
		
	_stopSpecialMousePointer: -> 
		AMouseTracker.stopTracking()	

	@_workspaceOffset: ->
		@_cachedWorkspaceOffset ?= $('#awcc-outline').offset()		

	@snapX: (currentX, objectWidth)->
		gridStep = @._getInstance().gridStep()
		leftSide = currentX - objectWidth/2
		leftAxisX = Math.floor((leftSide - @_workspaceOffset().left)/gridStep)*gridStep + @_workspaceOffset().left
		rightAxisX = Math.ceil((leftSide - @_workspaceOffset().left)/gridStep)*gridStep + @_workspaceOffset().left
		console.log(leftAxisX)
		console.log(rightAxisX)
		console.log(leftSide)
		if  (leftSide - leftAxisX) <= 10
            return leftAxisX + objectWidth/2
        else 
        	if (rightAxisX - leftSide) <= 10
        		return rightAxisX + objectWidth/2
        	else	
        		return currentX        	    
	@snapY: (currentY, objectHeight)->
		gridStep = @._getInstance().gridStep()
		workspaceTop = AWidgetWorkspace.__instance.domToGL(0, @_workspaceOffset().top).y
		topSide = currentY + objectHeight/2
		rest = (workspaceTop - topSide) % gridStep
		# bottomAxisY = Math.floor((workspaceTop - topSide)/gridStep)*gridStep + @_workspaceOffset().top
		# topAxisY = Math.ceil((workspaceTop - topSide)/gridStep)*gridStep + @_workspaceOffset().top 
		# console.log(workspaceTop - topSide)
		if  rest <= 10
            return currentY + rest
        else
        	if (gridStep - rest) <= 10
        		return currentY - gridStep + rest
        	else	
        		return currentY   
		    
            # else  
              # console.log(rightAxisX - _newX)
              # if (rightAxisX - _newX)<=5
                # _newX = rightAxisX

	
			
# <label for="gridZoom">Zoom:</label>
# 		        	<select name="gridZoom">
# 		        		<option value="0.25">0.25</option>
# 		        		<option value="0.5">0.5</option>
# 		        		<option value="1">1</option>
# 		        		<option value="1.25">1.25</option>
# 		        		<option value="1.5">1.5</option>
# 		        		<option value="2">2</option>	
# 		        	</select>
