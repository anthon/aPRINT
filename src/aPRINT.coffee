A = (selector,options)->
	
	_frame = null
	_body = null
	_pages = null
	_current_draggable = null
	_settings =
		baseStyle: '../aPRINT.css'
		stylesheet: null
		id: 'aPRINT'
		format: 'A4'

	init = (selector,options)->
		# Update _settings
		for key,value of options
			_settings[key] = value

		createIframe()
		activateContent()
		setupListeners()

	createIframe = ->
		_body = document.querySelector selector
		_frame = document.createElement 'iframe'
		_frame.width = _body.offsetWidth
		_frame.height = _body.offsetHeight
		_body.parentNode.insertBefore _frame, _body
		_frame.contentDocument.body.appendChild _body
		insertStyle _settings.baseStyle
		if _settings.stylesheet then insertStyle _settings.stylesheet

	insertStyle = (href)->
		styleLink = document.createElement 'link'
		styleLink.type = 'text/css'
		styleLink.rel = 'stylesheet'
		styleLink.href = href
		_frame.contentDocument.head.appendChild(styleLink)

	activateContent = ->
		sortables = _body.querySelectorAll '.sortable'
		removables = _body.querySelectorAll '.removable'
		for sortable in sortables
			disableNestedImageDrag sortable
			makeSortable sortable
		for removable in removables
			makeRemovable removable

	setupListeners = ->
		for drag,drop of _settings.rules
			addDragDroppable drag, drop

	addDragDroppable = (drag,drop)->
		drag_selector = drag
		if typeof drop is 'string'
			drop_selector = drop
		else if drop.target
			drop_selector = drop.target
		replace_on_drop = if typeof drop.replace is 'boolean' then drop.replace else false
		draggables = document.querySelectorAll drag_selector
		droppables = _body.querySelectorAll drop_selector
		
		for draggable in draggables
			draggable.draggable = true
			disableNestedImageDrag(draggable)
			draggable.addEventListener 'dragstart', (e)->
				e.dataTransfer.effectAllowed = 'move'
				_current_draggable = e.srcElement
				e.dataTransfer.setData 'drop_on', drop_selector
				draggable.classList.add 'drag'
				return false
			draggable.addEventListener 'dragend', (e)->
				draggable.classList.remove 'drag'
				_current_draggable = null
				return false
		
		for droppable in droppables
			droppable.addEventListener 'dragover', (e)->
				if e.dataTransfer.getData('drop_on') is drop_selector
					if e.preventDefault then e.preventDefault()
					e.dataTransfer.dropEffect = 'move'
					this.classList.add 'over'
				else if _current_draggable.parentNode is droppable
					if e.preventDefault then e.preventDefault()
					_current_draggable.style.opacity = 0
					if e.target is droppable
						insertNextTo _current_draggable, droppable.lastChild
					else
						insertNextTo _current_draggable, getSortable(e.target,droppable)
				return false

			droppable.addEventListener 'dragenter', (e)->
				if e.dataTransfer.getData('drop_on') is drop_selector
					this.classList.add 'over'
				return false

			droppable.addEventListener 'dragleave', (e)->
				this.classList.remove 'over'
				return false

			droppable.addEventListener 'drop', (e)->
				if e.stopPropagation then e.stopPropagation()
				if e.dataTransfer.getData('drop_on') is drop_selector
					this.classList.remove 'over'
					clone = _current_draggable.cloneNode(true)
					makeRemovable clone
					if replace_on_drop
						droppable.innerHTML = ''
						droppable.appendChild clone
					else
						makeSortable clone
						if e.target is droppable
							droppable.appendChild clone
						else
							insertNextTo clone, getSortable(e.target,droppable)
				return false

	disableNestedImageDrag = (el)->
		images_in_draggable = el.querySelectorAll 'img'
		for image in images_in_draggable
			image.style['user-drag'] = 'none'
			image.style['-moz-user-select'] = 'none'
			image.style['-webkit-user-drag'] = 'none'

	makeRemovable = (el)->
		el.classList.add 'removable'
		trasher = el.querySelector '.remove'
		if not trasher
			trasher = document.createElement 'div'
			trasher.innerHTML = '&times;'
			trasher.classList.add 'remove'
			el.appendChild trasher
		trasher.addEventListener 'click', onTrashClick

	makeSortable = (el)->
		el.draggable = true
		el.classList.add 'sortable'
		el.addEventListener 'dragstart', (e)->
			e.dataTransfer.dropEffect = 'move'
			e.dataTransfer.effectAllowed = 'move'
			_current_draggable = e.srcElement
			el.classList.add 'drag'
			return false
		el.addEventListener 'dragend', (e)->
			el.classList.remove 'drag'
			_current_draggable.style.opacity = 1
			_current_draggable = null
			return false

	insertNextTo = (el,sibling)->
		parent = sibling.parentNode
		if el.parentNode is parent
			siblings = parent.childNodes
			el_index = Array.prototype.indexOf.call siblings, el
			sibling_index = Array.prototype.indexOf.call siblings, sibling
			if el_index > sibling_index
				parent.insertBefore el, sibling
			else
				parent.insertBefore el, sibling.nextSibling
		else
			parent.insertBefore el, sibling

	getSortable = (el,parent)->
		loop
			el_parent = el.parentNode
			break if el_parent is parent
			el = el_parent
		console.log el
		return el

	onTrashClick = (e)->
		el = e.target.parentNode
		el.remove()

	print = ->
		#

	init(selector,options)

	return {
		print: print
	}

window.aPRINT = (selector,options)->
	new A(selector,options)