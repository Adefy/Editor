class AMouseTracker

	@startTracking: (workspace)->
		@_workspaceWidth = @_getWorkspace().width()
		@_workspaceHeight = @_getWorkspace().height()
		@_jCanvas().on('mousemove.pointer', (event)=>
			if @_prevX && @_prevY
				if ((Math.abs(@_prevX - event.pageX) <=3) && (Math.abs(@_prevY - event.pageY) <=3)) 
					@_prevX = event.pageX
					@_prevY = event.pageY
					return true
				else
					@_prevX = event.pageX
					@_prevY = event.pageY
			else
				@_prevX = event.pageX
				@_prevY = event.pageY
			if @_pointerInWorkspace(event)
				@_drawAxis(event, workspace)
				if !@_jCanvas().hasClass('without-cursor')
					@_jCanvas().addClass('without-cursor')
				
			else
				@_jCanvas().removeClass('without-cursor')
				@_destroyAxis()
			return true
		)
	# @_yAxis = $('<div/>', {id: 'yAxis'}).appendTo($('#aw-canvas-container'))
	# 	@_xAxis = $('<div/>', {id: 'xAxis'}).appendTo($('#aw-canvas-container'))
	# 	@_yAxis.css(position: 'absolute', background: 'black', width: '1px');
	# 	@_xAxis.css(position: 'absolute', background: 'black', height: "1px" );
	

	@stopTracking: ->
		@_jCanvas.off('mousemove.pointer')
		@_jCanvas().removeClass('without-cursor')
		@_destroyAxis()

	@_destroyAxis: ->	
		if @_currentYAxis && @_currentXAxis
			@_currentXAxis.destroy()
			@_currentYAxis.destroy()
			@_currentXAxis = null
			@_currentYAxis = null

	@_jCanvas: ->
		@_jCachedCanvas ?= $('#awgl_canvas')	

	# TODO: cache offset
	@_workspaceAreaBounds: ->
		@_cachedBounds ?= @_getWorkspace().offset()	 

	@resetCachedBounds: ->
		@_cachedBounds = null	

	@_getWorkspace: ->
		@_cachedWorkspace ?= $('#awcc-outline')	
		
	@_pointerInWorkspace: (event)->
		top = @_workspaceAreaBounds().top 
		bottom = @_workspaceAreaBounds().top + @_workspaceHeight
		left = @_workspaceAreaBounds().left 
		right = @_workspaceAreaBounds().left + @_workspaceWidth
		(event.pageX > left) && (event.pageX < right) && 
			(event.pageY > top) && (event.pageY < bottom)	

	@_drawAxis: (event)->
		if @_currentYAxis && @_currentXAxis
			pointY = workspace.domToGL(event.pageX, @_workspaceAreaBounds().top + @_workspaceHeight/2) 
			pointX = workspace.domToGL(@_workspaceAreaBounds().left + @_workspaceWidth/2, event.pageY)
			@_currentYAxis.setPosition(new AJSVector2(pointY.x, pointY.y))
			@_currentXAxis.setPosition(new AJSVector2(pointX.x, pointX.y))
			return true
		gridColor = new AJSColor3(0, 0, 0)		
		pointY = workspace.domToGL(event.pageX, @_workspaceAreaBounds().top + @_workspaceHeight/2) 
		pointX = workspace.domToGL(@_workspaceAreaBounds().left + @_workspaceWidth/2, event.pageY)
		currentYPosition = new AJSVector2(pointY.x, pointY.y)
		@_currentYAxis = new AJSRectangle(
			w: 1, 
			h: @_workspaceHeight, 
			mass: 1.0, 
			friction: 0, 
			elasticity: 1.0, 
			color: gridColor, 
			position: currentYPosition, 
			rotation: 0, 
			psyx: false
		)
		currentXPosition = new AJSVector2(pointX.x, pointX.y)
		@_currentXAxis = new AJSRectangle(
			w: @_workspaceWidth, 
			h: 1, 
			mass: 1.0, 
			friction: 0, 
			elasticity: 1.0, 
			color: gridColor, 
			position: currentXPosition, 
			rotation: 0, 
			psyx: false
		)
				# @_yAxis.css(
		# 	left: "#{event.pageX}px"
		# 	top:  "#{@_getWorkspace().position().top}px"
		# 	height: "480px" 
		# 	display: 'block'
		# )
		# @_xAxis.css(
		# 	left: "#{@_getWorkspace().position().left}px"
		# 	top:  "#{event.offsetY}px"
		# 	width: "800px"
		# 	display: 'block'
		# )
		# console.timeEnd '<<<'
	
