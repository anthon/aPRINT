A = (selector,options)->
	
	_frame = null
	_body = null
	_pages = null
	_callbacks = {}
	_current_draggable = null
	_current_drop_selector = null
	_baseStyle = 	'* {
					  -webkit-box-sizing: border-box;
					  -moz-box-sizing: border-box;
					  -ms-box-sizing: border-box;
					  -o-box-sizing: border-box;
					  box-sizing: border-box;
					  margin: 0;
					  padding: 0;
					  outline: none;
					}
					html {
					  font-size: 0.428571428571429vw;
					}
					body {
					  background: #808080;
					}
					body .over {
					  background: #94ff94;
					}
					body .removable {
					  position: relative;
					}
					body .removable .remove {
					  font-family: sans-serif;
					  background: #fff;
					  position: absolute;
					  top: 6px;
					  right: 6px;
					  padding: 3px 7px;
					  font-size: 13px;
					  font-weight: 100;
					  color: #000;
					  cursor: pointer;
					}
					body .removable .remove:hover {
					  background: #c20000;
					  color: #fff;
					}
					body .page {
					  background: #fff;
					  width: 90vw;
					  margin: 4rem auto;
					}
					body .page.A4 {
					  height: 127.28571428571429vw;
					}
					@media print {
					  html {
					    font-size: 4.2333336mm;
					  }
					  html body .page.A4 {
					    width: 210mm;
					    height: 297mm;
					  }
					}'
	_settings =
		# baseStyle: '../aPRINT.css'
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
		# _frame.style.borderWidth = 0
		_frame.style.resize = 'horizontal'
		_body.parentNode.insertBefore _frame, _body
		_frame.contentDocument.body.appendChild _body
		if _settings.baseStyle
			insertStyle _settings.baseStyle, true
		else
			insertStyle _baseStyle
		if _settings.stylesheet then insertStyle _settings.stylesheet, true

	insertStyle = (style,is_link)->
		if is_link
			styleLink = document.createElement 'link'
			styleLink.type = 'text/css'
			styleLink.rel = 'stylesheet'
			styleLink.href = style
			_frame.contentDocument.head.appendChild(styleLink)
		else
			styleTag = document.createElement 'style'
			styleTag.innerHTML = style
			_frame.contentDocument.head.appendChild(styleTag)

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
				_current_drop_selector = drop_selector
				draggable.classList.add 'drag'
				return false
			draggable.addEventListener 'dragend', (e)->
				draggable.classList.remove 'drag'
				_current_draggable = null
				return false
		
		for droppable in droppables
			droppable.addEventListener 'dragover', (e)->
				if _current_drop_selector is drop_selector
					if e.preventDefault then e.preventDefault()
					e.dataTransfer.dropEffect = 'move'
					droppable.classList.add 'over'
					fireCallbacks('dragover',e)
				else if _current_draggable.parentNode is droppable
					if e.preventDefault then e.preventDefault()
					_current_draggable.style.opacity = 0
					if e.target is droppable
						insertNextTo _current_draggable, droppable.lastChild
					else
						insertNextTo _current_draggable, getSortable(e.target,droppable)
					fireCallbacks('dragover',e)
				return false

			droppable.addEventListener 'dragenter', (e)->
				if _current_drop_selector is drop_selector
					droppable.classList.add 'over'
					fireCallbacks('dragenter',e)
				return false

			droppable.addEventListener 'dragleave', (e)->
				droppable.classList.remove 'over'
				return false

			droppable.addEventListener 'drop', (e)->
				if e.stopPropagation then e.stopPropagation()
				if _current_drop_selector is drop_selector
					droppable.classList.remove 'over'
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
					fireCallbacks('drop update',e)
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
		fireCallbacks 'remove update', e

	setCallback = (key,callback)->
		if not _callbacks[key] then _callbacks[key] = []
		_callbacks[key].push callback

	fireCallbacks = (key,e)->
		keys = key.split ' '
		for k in keys
			console.log _callbacks
			if _callbacks[k]
				for callback in _callbacks[k]
					callback(e)

	getHTML = (page)->
		if page and typeof page is 'Integer' then return _pages[page].outerHTML
		return _body.outerHTML

	print = ->
		#

	init(selector,options)

	return {
		print: print
		on: setCallback
		get: getHTML
	}

window.aPRINT = (selector,options)->
	new A(selector,options)