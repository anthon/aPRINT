A = (body,options)->
	
	_frame = null
	_body = null
	_pages = null
	_callbacks = {}
	_current_draggable = null
	_current_drop_selector = null
	_current_sortable_target = null
	_is_sorting = false
	_settings =
		styles: ['../aPRINT.css']
		id: 'aPRINT'
		format: 'A4'
		transparent: false
		margins:
			left: ''

	init = (body,options)->
		# Update _settings
		for key,value of options
			_settings[key] = value
		_body = body
		createIframe()

	createIframe = ->
		_pages = _body.querySelectorAll '.page'
		_frame = document.createElement 'iframe'
		_frame.width = _body.offsetWidth
		_frame.style.borderWidth = 0
		_frame.style.resize = 'horizontal'
		if _settings.transparent then _frame.setAttribute 'allowtransparency', true
		# _frame.src = 'about:blank'
		_body.parentNode.insertBefore _frame, _body
		window.addEventListener 'resize', onWindowResize
		if _frame.contentWindow.document.readyState is 'complete'
			populateIframe()
		else
			_frame.contentWindow.addEventListener 'load', ->
				populateIframe()

	populateIframe = ->
		_frame.contentDocument.body.appendChild _body
		if typeof _settings.styles is 'string' then _settings.styles = [_settings.styles]
		for stylesheet in _settings.styles
			insertStyle stylesheet
		activateContent()
		setupListeners()
		frameResize()

	insertStyle = (style)->
		styleLink = document.createElement 'link'
		styleLink.type = 'text/css'
		styleLink.rel = 'stylesheet'
		styleLink.href = style
		_frame.contentDocument.head.appendChild(styleLink)

	addEventListener = (el,evt,callback)->
		el.removeEventListener evt, callback
		el.addEventListener evt, callback

	activateContent = ->
		sortables = _body.querySelectorAll '.sortable'
		removables = _body.querySelectorAll '.removable'
		classables = _body.querySelectorAll '.classable'
		for page in _pages
			disableNestedImageDrag page
			# makeSortable page
			addAddPage page
		for sortable in sortables
			disableNestedImageDrag sortable
			makeSortable sortable
		for removable in removables
			makeRemovable removable
		for classable in classables
			console.log classable
			makeClassable classable

	onWindowResize = (e)->
		frameResize()

	frameResize = ->
		_frame.height = _frame.contentDocument.body.offsetHeight

	addAddPage = (page)->
		adder = document.createElement 'div'
		adder.classList.add 'add_page'
		adder.innerHTML = '+'
		adder.addEventListener 'click', addPage
		_body.insertBefore adder, page.nextSibling

	setupListeners = ->
		for drag,drop of _settings.rules
			addDragDroppable drag, drop

	onDraggableDragStart = (e)->
		that = this
		e.dataTransfer.effectAllowed = 'move'
		e.dataTransfer.setData 'source','external'
		_current_draggable = e.target
		_current_drop_selector = that.dataset.dropSelector
		that.classList.add 'drag'
		return false

	onDraggableDragEnd = (e)->
		that = this
		that.classList.remove 'drag'
		_current_draggable = null
		_current_drop_selector = null
		return false

	onDroppableDragOver = (e)->
		that = this
		if _current_drop_selector is that.dataset.dropSelector
			if e.preventDefault then e.preventDefault()
			e.dataTransfer.dropEffect = 'move'
			that.classList.add 'over'
			fireCallbacks('dragover',e)
		else if _is_sorting
			if e.preventDefault then e.preventDefault()
			_current_draggable.style.opacity = 0
			if e.target is that
				insertNextTo _current_draggable, that.lastChild
			else if _current_sortable_target isnt _current_draggable
				insertNextTo _current_draggable, getSortable(e.target,that)
			fireCallbacks('dragover',e)
		return false

	onDroppableDragEnter = (e)->
		that = this
		if _current_drop_selector is that.dataset.dropSelector
			that.classList.add 'over'
			fireCallbacks('dragenter',e)
		return false

	onDroppableDragLeave = (e)->
		that = this
		that.classList.remove 'over'
		return false

	onDroppableDrop = (e)->
		that = this
		if e.stopPropagation then e.stopPropagation()
		if _current_drop_selector is that.dataset.dropSelector
			that.classList.remove 'over'
			clone = _current_draggable.cloneNode(true)
			makeRemovable clone
			makeClassable clone
			if that.dataset.replace
				that.innerHTML = ''
				that.appendChild clone
			else
				makeSortable clone
				if e.target is that
					that.appendChild clone
				else
					insertNextTo clone, getSortable(e.target,that)
			if clone_img = clone.querySelector 'img'
				clone_img.onload = ->
					checkOverflow(that,clone)
			else
				checkOverflow(that,clone)
			fireCallbacks 'drop'
		return false

	addDragDroppable = (drag,drop)->
		drag_selector = drag
		if typeof drop is 'string'
			drop_selector = drop
		else if drop.target
			drop_selector = drop.target
		replace_on_drop = if typeof drop.replace is 'boolean' then drop.replace else false
		overflow_action = if drop.overflow then drop.overflow else false
		drop_classes = if drop.classes then drop.classes else false
		draggables = document.querySelectorAll drag_selector
		droppables = _body.querySelectorAll drop_selector
		
		for draggable in draggables
			draggable.draggable = true
			if drop_classes then draggable.dataset.classList = drop_classes
			draggable.dataset.dropSelector = drop_selector
			disableNestedImageDrag(draggable)
			
			addEventListener draggable, 'dragstart', onDraggableDragStart
			addEventListener draggable, 'dragend', onDraggableDragEnd
		
		for droppable in droppables
			droppable.dataset.dropSelector = drop_selector
			droppable.dataset.overflowAction = overflow_action
			if replace_on_drop then droppable.dataset.replace = true

			addEventListener droppable, 'dragover', onDroppableDragOver
			addEventListener droppable, 'dragenter', onDroppableDragEnter
			addEventListener droppable, 'dragleave', onDroppableDragLeave
			addEventListener droppable, 'drop', onDroppableDrop

	disableNestedImageDrag = (el)->
		images_in_draggable = el.querySelectorAll 'img'
		for image in images_in_draggable
			image.draggable = false
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

	makeClassable = (el)->
		if el.dataset.classList
			el.classList.add 'classable'
			items = el.querySelectorAll '.classes .item'
			class_list = el.dataset.classList.split ','
			if items.length is 0
				container = document.createElement 'div'
				container.classList.add 'classes'
				expander = document.createElement 'div'
				expander.classList.add 'expander'
				expander.innerHTML = '&bull;'
				container.appendChild expander
				list = document.createElement 'div'
				list.classList.add 'list'
				class_list.unshift 'none'
				for cls in class_list
					item = document.createElement 'div'
					item.classList.add 'item'
					item.innerHTML = cls
					list.appendChild item
				items = list.querySelectorAll '.item'
				container.appendChild list
				el.appendChild container
			for item in items
				item.addEventListener 'click', (e)->
					for cls in class_list
						el.classList.remove cls
					el.classList.add this.innerHTML
					checkOverflow el.parentNode

	makeSortable = (el)->
		el.draggable = true
		el.classList.add 'sortable'
		el.addEventListener 'dragstart', (e)->
			e.dataTransfer.dropEffect = 'move'
			e.dataTransfer.effectAllowed = 'move'
			e.dataTransfer.setData 'source','internal'
			_current_draggable = e.target
			_current_draggable.classList.add 'drag'
			_is_sorting = true
			return false
		el.addEventListener 'dragend', (e)->
			_current_draggable.classList.remove 'drag'
			_current_draggable.style.opacity = 1
			checkOverflow e.target.parentNode
			_current_draggable = null
			_is_sorting = false
			return false
		el.addEventListener 'dragover', (e)->
			_current_sortable_target = el

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
		return el

	addPage = (e)->
		that = this
		page = that.previousSibling
		new_page = _body.querySelector('.page').cloneNode true
		removables = new_page.querySelectorAll '.removable'
		for removable in removables
			removable.remove()
		_body.insertBefore new_page, that.nextSibling
		addAddPage new_page
		setupListeners()

	onTrashClick = (e)->
		el = e.target.parentNode
		droppable = el.parentNode
		el.remove()
		checkOverflow droppable
		fireCallbacks 'remove', e

	checkOverflow = (droppable,element)->
		if _is_sorting or not element
			els = droppable.querySelectorAll '.removable'
			for el in els
				el.style.height = 'auto'
		if droppable.scrollHeight > droppable.clientHeight
			action = droppable.dataset.overflowAction
			switch action
				when 'shrinkAll'
					els = droppable.querySelectorAll '.removable'
					l = els.length
					for el in els
						el.style.maxHeight = (100/l)+'%'
					fireCallbacks 'update'
				when 'shrinkLast'
					last_el = droppable.lastElementChild
					overflow = droppable.scrollHeight - droppable.clientHeight
					max_height = last_el.clientHeight - overflow
					max_height_percentage = (max_height/droppable.clientHeight)*100
					console.log max_height_percentage
					if max_height_percentage > 1
						last_el.style.height = max_height_percentage+'%'
						fireCallbacks 'update'
					else
						if not _is_sorting then element.remove()
						refuseDrop droppable
				else
					if not _is_sorting then element.remove()
					refuseDrop droppable
		else
			fireCallbacks 'update'

	refuseDrop = (droppable)->
		droppable.classList.add 'nodrop'
		droppable.offsetWidth = droppable.offsetWidth
		droppable.classList.add 'fade'
		droppable.offsetWidth = droppable.offsetWidth
		droppable.classList.remove 'nodrop'
		setTimeout ->
			droppable.classList.remove 'fade'
		,1000

	setCallback = (key,callback)->
		if not _callbacks[key] then _callbacks[key] = []
		_callbacks[key].push callback

	fireCallbacks = (key,e)->
		keys = key.split ' '
		for k in keys
			if _callbacks[k]
				for callback in _callbacks[k]
					callback(e)

	getHTML = (page)->
		if page and typeof page is 'Integer'
			clone = _pages[page].cloneNode true
		else
			clone = _body.cloneNode true
		console.log clone
		to_removes = clone.querySelectorAll '.add_page, .classes, .remove'
		for to_remove in to_removes
			to_remove.remove()
		return clone.innerHTML

	print = ->
		#

	init(body,options)

	return {
		print: print
		on: setCallback
		get: getHTML
	}

window.aPRINT = (el,options)->
	if typeof el is 'string'
		el = document.querySelector(el)
		if not el then return false
	return new A(el,options)
