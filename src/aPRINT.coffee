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
		editable: true
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
		_frame.style.overflow = 'hidden'
		# _frame.style.resize = 'horizontal'
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
		refreshPageNumbers()
		if typeof _settings.styles is 'string' then _settings.styles = [_settings.styles]
		for stylesheet in _settings.styles
			insertStyle stylesheet
		insertSizer()
		if _settings.editable
			activateContent()
			setupListeners()
		activatePrinter()
		setTimeout ->
			frameResize()
		,200

	insertSizer = ->
		sizer = document.createElement 'style'
		sizer.id = 'sizer'
		_frame.contentDocument.head.appendChild sizer

	insertStyle = (style)->
		styleLink = document.createElement 'link'
		styleLink.type = 'text/css'
		styleLink.rel = 'stylesheet'
		styleLink.href = style
		_frame.contentDocument.head.appendChild styleLink

	addEventListener = (el,evt,callback)->
		el.removeEventListener evt, callback
		el.addEventListener evt, callback

	activateContent = ->
		items = _body.querySelectorAll '[data-item]'
		for page in _pages
			disableNestedImageDrag page
			# makeSortable page
			addAddPage page
		for item in items
			addFeatures item

	activatePrinter = ->
		document.addEventListener 'keydown', (e)->
			if e.metaKey && e.keyCode is 80
				e.preventDefault()
				print()
				return false

	onWindowResize = (e)->
		console.log 'resizing'
		frameResize()

	frameResize = ->
		mm2px = 3.78
		paper_width = 210
		margin = 16
		max_width = (paper_width + margin) * mm2px
		act_widh = _frame.offsetWidth
		factor = act_widh / max_width
		_frame.contentDocument.body.style.transformOrigin = '0 0'
		_frame.contentDocument.body.style.transform = 'scale('+factor+')'
		_frame.height = (_body.scrollHeight + 12)*factor
		# pageWidth = .9 * _body.offsetWidth
		# a4width = 210
		# a4height = 297
		# a4mm = ((100/a4width)*(pageWidth/100))
		# _frame.contentDocument.querySelector('#sizer').innerHTML = 'html{font-size:'+a4mm+'px}'

	refreshPageNumbers = ->
		_pages = _body.querySelectorAll '.page'
		seq = 'odd'
		for page in _pages
			page.classList.remove('even','odd')
			page.classList.add seq
			seq = if seq is 'odd' then 'even' else 'odd'

	addAddPage = (page)->
		adder = document.createElement 'div'
		adder.classList.add 'add_page'
		adder.innerHTML = '+'
		adder.addEventListener 'click', onAddPageClick
		page.appendChild adder

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
			clone.removeAttribute 'draggable'
			itemise clone
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
			makeRemovable clone
			makeClassable clone
		else if _is_sorting
			checkOverflow that
		fireCallbacks 'drop'
		return false

	itemise = (el,sibling)->
		el.dataset.item = if sibling then sibling.dataset.id else getID()

	addDragDroppable = (drag,drop)->
		drag_selector = drag
		if typeof drop is 'string'
			drop_selector = drop
		else if drop.target
			drop_selector = drop.target
		replace_on_drop = if typeof drop.replace is 'boolean' then drop.replace else false
		removable = if typeof drop.removable is 'boolean' then drop.removable else true
		sortable = if typeof drop.sortable is 'boolean' then drop.sortable else true
		overflow_action = if drop.overflow then drop.overflow else false
		drop_classes = if drop.classes then drop.classes else false
		draggables = document.querySelectorAll drag_selector
		droppables = _body.querySelectorAll drop_selector
		
		for draggable in draggables
			draggable.draggable = true
			if drop_classes then draggable.dataset.classList = drop_classes
			if removable then draggable.dataset.removable = removable
			if sortable then draggable.dataset.sortable = sortable
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

	addFeatures = (el)->
		makeSortable el	
		makeRemovable el
		makeClassable el

	makeRemovable = (el)->
		if el.dataset.removable
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
					set = _body.querySelectorAll '[data-item="'+el.dataset.item+'"]'
					for set_el in set
						for cls in class_list
							set_el.classList.remove cls
						set_el.classList.add this.innerHTML
						checkOverflow set_el.parentNode

	makeSortable = (el)->
		if el.dataset.sortable
			disableNestedImageDrag el
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
				# Dirty hack in case of no _current_draggable
				if _current_draggable
					_current_draggable.classList.remove 'drag'
					_current_draggable.style.opacity = 1
					checkOverflow e.target.parentNode
					_current_draggable = null
					_is_sorting = false
					return false
			el.addEventListener 'dragover', (e)->
				_current_sortable_target = el
				consolidate _current_sortable_target

	removeFeatures = (el)->
		to_removes = el.querySelectorAll '.add_page, .classes, .remove'
		for to_remove in to_removes
			to_remove.remove()

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

	onAddPageClick = (e)->
		addPage e.target.parentNode

	addPage = (page)->
		new_page = _body.querySelector('.page').cloneNode true
		items = new_page.querySelectorAll '[data-item],.add_page'
		for item in items
			item.remove()
		_body.insertBefore new_page, page.nextSibling
		addAddPage new_page
		refreshPageNumbers()
		frameResize()
		setupListeners()
		return new_page

	onTrashClick = (e)->
		el = e.target.parentNode
		set = _body.querySelectorAll '[data-item="'+el.dataset.item+'"]'
		for set_el in set
			droppable = set_el.parentNode
			set_el.remove()
			checkOverflow droppable
		fireCallbacks 'remove', e

	consolidate = (el)->
		els = _body.querySelectorAll '[data-item="'+el.dataset.item+'"]'
		if els.length > 1
			for set_el in els
				if set_el is el
					set_el.innerHTML = set_el.dataset.content
					addFeatures set_el
					delete set_el.dataset.content
				else
					set_el.remove()

	checkOverflow = (droppable,element)->
		if _is_sorting or not element
			els = droppable.querySelectorAll '[data-item]'
			for el in els
				el.style.height = 'auto'
		if droppable.scrollHeight > droppable.clientHeight
			action = droppable.dataset.overflowAction
			switch action
				when 'continue'
					# This only applies to texts for now
					last_el = droppable.lastElementChild
					removeFeatures last_el
					last_el.dataset.content = last_el.innerHTML
					continuer = last_el.cloneNode()
					l = 200
					while l-- and droppable.scrollHeight > droppable.clientHeight
						lc = last_el.lastChild
						if not lc
							last_el.remove()
							refuseDrop droppable
							return false
						switch lc.nodeType
							when 1
								# Is element
								continuer.insertBefore lc, continuer.firstChild
							when 3
								# Is text node
								if /\S/.test lc.nodeValue
									# should split up
								else
									lc.remove()
							else
								# No idea
					fc = continuer.firstChild
					cl = fc.cloneNode()
					last_el.appendChild fc
					cl.innerHTML = ''
					l = 200
					while l-- and droppable.scrollHeight > droppable.clientHeight
						fcHTML = fc.innerHTML.split(' ')
						cl.innerHTML = fcHTML.pop()+' '+cl.innerHTML
						fc.innerHTML = fcHTML.join(' ')
					continuer.insertBefore cl, continuer.firstChild
					page = parentPage droppable
					next_page = page.nextSibling
					if not next_page or next_page.nodeType isnt 1
						next_page = addPage page
					drp = next_page.querySelector '.'+droppable.className
					drp.insertBefore continuer, drp.firstChild
					addFeatures last_el
					checkOverflow drp
					fireCallbacks 'update'
						
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

	parentPage = (el)->
		while not el.classList.contains 'page'
			el = el.parentNode
		return el

	getID = ->
		return Math.random().toString(36).substring 8

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
		removeFeatures clone
		return clone.innerHTML

	print = ->
		_frame.contentWindow.print()

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
