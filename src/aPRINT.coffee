A = (body,options)->
	
	# Constants
	_mm2px = 3.78
	_A4_width = 210

	# Globals
	_frame = null
	_body = null
	_sections = null
	_callbacks = {}
	_current_draggable = null
	_current_drag_selector = null
	_current_sortable_target = null
	_drag_image = null
	_is_sorting = false
	_rules = {}
	_current_rule = null
	_settings =
		styles: ['../aPRINT.css']
		id: 'aPRINT'
		format: 'A4'
		transparent: false
		editable: true
		mirror: true
		margins:
			left: ''

	init = (body,options)->
		# Update _settings
		for key,value of options
			_settings[key] = value
		_settings.format = {
			screen: _settings.format.screen || _settings.format,
			print: _settings.format.print || _settings.format
		}
		_body = body
		createIframe()

	createIframe = ->
		_frame = document.createElement 'iframe'
		_frame.style.borderWidth = 0
		# _frame.style.overflow = 'hidden'
		# _frame.style.resize = 'horizontal'

		# Creating drag image container
		_drag_image = document.querySelector '#aPRINT-image-drag'
		if not _drag_image
			_drag_image = document.createElement 'div'
			_drag_image.id = 'aPRINT-image-drag'
			_drag_image.style.width = '124px'
			_drag_image.style.height = '124px'
			_drag_image.style.backgroundPosition = 'center center'
			_drag_image.style.backgroundSize = 'contain'
			document.body.appendChild _drag_image

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
		_frame.contentDocument.body.classList.add _settings.format.screen
		_frame.contentDocument.body.appendChild _body
		if typeof _settings.styles is 'string' then _settings.styles = [_settings.styles]
		for stylesheet in _settings.styles
			insertStyle stylesheet
		# insertSizer()
		if _settings.template then renderTemplate()
		if _settings.editable
			applyRules()
			activateContent()
		activateKeys()
		frameResize()
		refreshPages()
		fireCallbacks 'loaded'

	# insertSizer = ->
	# 	sizer = document.createElement 'style'
	# 	sizer.id = 'sizer'
	# 	_frame.contentDocument.head.appendChild sizer

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
		pages = _body.querySelectorAll '.page'
		for page in pages
			disableNestedImageDrag page
			# makeSortable page
			addPageFeatures page
		items = _body.querySelectorAll '[data-item]'
		for item in items
			addFeatures item

	activateKeys = ->
		document.addEventListener 'keydown', onKeyDown
		_frame.contentDocument.addEventListener 'keydown', onKeyDown

	onKeyDown = (e)->
		switch e.keyCode
			when 80
				# p
				if e.metaKey
					e.preventDefault()
					print()
					return false
			when 40
				# down
				if e.shiftKey
					scrollToEl 'section'
				else
					scrollToEl '.page'
			when 38
				# up
				if e.shiftKey
					scrollToEl 'section', true
				else
					scrollToEl '.page', true

	scrollTo = (target,duration)->
		if typeof target is 'string' then target = _body.querySelector target
		if target and target.getBoundingClientRect
			if not duration then duration = 200
			section = if target.nodeName is 'SECTION' then target else target.parentNode
			section_id = section.dataset.id
			# console.log 'section id', section_id
			body = _frame.contentDocument.body
			start = body.scrollTop
			target_top = Math.round(target.getBoundingClientRect().top + start)
			change = if target then target_top - start else 0 - start
			currentTime = 0
			increment = 20
			animate = ->
				currentTime += increment
				scrollTop = Math.easeInOutQuad currentTime,start,change,duration
				body.scrollTop = scrollTop
				if currentTime < duration
					setTimeout animate, increment
			animate()
			fireCallbacks('scroll',section_id)

	scrollToEl = (selector,reverse)->
		els = _body.querySelectorAll selector
		wb = _frame.contentWindow.innerHeight
		for el,index in els
			r = el.getBoundingClientRect()
			r_top = Math.round(r.top)
			r_bottom = Math.round(r.bottom)
			if reverse
				if r_top >= 0 and r_top <= wb
					return scrollTo els[index-1]
				if r_top <= 0 and r_bottom >= wb
					return scrollTo el
			else
				if r_top > 0 and r_top < wb
					return scrollTo el
				if (r_top == 0 and r_top < wb) or (r_top <= 0 and r_bottom >= wb)
					return scrollTo els[index+1]

	onWindowResize = (e)->
		frameResize()

	frameResize = ->
		margin = 12
		paper_width = if _settings.format.screen == 'A4' then _A4_width else _A4_width*2+margin
		max_width = (paper_width + margin*2) * _mm2px
		act_width = _frame.offsetWidth
		factor = act_width / max_width
		# _frame.contentDocument.body.style.transformOrigin = ((margin*2)*factor)+'px 0'
		_frame.contentDocument.body.style.transform = 'scale('+factor+')'
		_frame.contentDocument.body.style.marginLeft = ((act_width - max_width)/2 + margin*2)+'px'
		# _frame.contentDocument.body.style.height = _frame.contentDocument.body.getBoundingClientRect().height
		# console.log _frame.contentDocument.body.getBoundingClientRect().height
		# pageWidth = .9 * _body.offsetWidth
		# a4width = 210
		# a4height = 297
		# a4mm = ((100/a4width)*(pageWidth/100))
		# _frame.contentDocument.querySelector('#sizer').innerHTML = 'html{font-size:'+a4mm+'px}'

	renderTemplate = ->
		placeholder = _body.querySelector 'section'
		if not placeholder
			from_scratch = true
			placeholder = document.createElement 'section'
		else
			from_scratch = false
		placeholders = [placeholder]
		for key,element of _settings.template
			walkTemplate placeholders, key, element, (parent,identifier,element)->
				nodes = _body.querySelectorAll '[data-template-identifier='+identifier+']'
				if nodes.length is 0
					node = createNode identifier
					parent.appendChild node
					nodes = [node]
				for node in nodes
					# if element.children
					# 	_node = node.cloneNode false
					# 	for id,child of element.children
					# 		child_node = getNode id, node
					# 		if not child_node
					# 			console.log(id)
					# 			child_node = createNode id
					# 		_node.appendChild child_node
					# 	node.innerHTML = _node.innerHTML
						# child_identifiers = Object.keys element.children
						# child_nodes = node.children
						# for child_node in child_nodes
						# 	if child_node and
						# 		child_node.dataset.templateIdentifier and
						# 		child_identifiers.indexOf(child_node.dataset.templateIdentifier) is -1
						# 			child_node.remove()

					if element.classes
						node.classList.remove()
						for cls in element.classes
							node.classList.add cls
				return nodes
		if from_scratch then _body.appendChild placeholder

	getNode = (identifier,parent)->
		parent = parent || _body
		parent.querySelector '[data-template-identifier='+identifier+']'

	getNodes = (identifier,parent)->
		parent = parent || _body
		parent.querySelectorAll '[data-template-identifier='+identifier+']'

	createNode = (identifier)->
		node = document.createElement 'div'
		node.dataset.templateIdentifier = identifier
		return node

	walkTemplate = (parent_nodes,identifier,element,func)->
		for parent_node in parent_nodes
			nodes = func parent_node, identifier, element
			children = if element.children then element.children else {}
			for key,child of children
				walkTemplate nodes, key, child, func

	updateDOM = ->
		walkDOM _body, (node)->
			# Do stuff here

	walkDOM = (node,func)->
		func node
		node = node.firstChild
		while node
			walkTemplate node, func
			node = node.nextSibling

	refreshPages = ->
		if _settings.mirror
			_sections = _body.querySelectorAll 'section'
			for section in _sections
				pages = section.querySelectorAll '.page'
				seq = 'odd'
				for page in pages
					page.classList.remove('even','odd')
					page.classList.add seq
					seq = if seq is 'odd' then 'even' else 'odd'

	addPageFeatures = (page)->
		if page.dataset.repeatable
			adder = page.querySelector '.add_page'
			if not adder
				adder = document.createElement 'div'
				adder.classList.add 'add_page'
				adder.innerHTML = '+'
				page.appendChild adder
			adder.addEventListener 'click', onAddPageClick
		if page.dataset.removable
			trasher = page.querySelector '.remove'
			if not trasher
				trasher = document.createElement 'div'
				trasher.innerHTML = '&times;'
				trasher.classList.add 'remove'
				page.appendChild trasher
			trasher.addEventListener 'click', onTrashClick

	itemise = (el,sibling)->
		delete el.dataset.selector
		el.dataset.item = if sibling then sibling.dataset.id else getID()

	applyRules = ->
		for target,rule of _settings.rules
			applyRule target,rule

	applyRule = (target,rule)->
		target_selector = target
		targets = _body.querySelectorAll target_selector

		removable = if typeof rule.removable is 'boolean' then rule.removable else false
		repeatable = if typeof rule.repeatable is 'boolean' then rule.repeatable else false

		for target in targets
			if removable then target.dataset.removable = removable
			if repeatable then target.dataset.repeatable = repeatable
		
		if rule.accept
			drag_selectors = if typeof rule.accept is 'string' then [rule.accept] else rule.accept

			replaceable = if typeof rule.replaceable is 'boolean' then rule.replaceable else false
			sortable = if typeof rule.sortable is 'boolean' then rule.sortable else false
			overflow_action = if rule.overflow then rule.overflow else false
			drop_classes = if rule.classes then rule.classes else false

			for droppable in targets
				if drop_classes then droppable.dataset.classList = JSON.stringify(drop_classes)
				if sortable then droppable.dataset.sortable = sortable
				if replaceable then droppable.dataset.replaceable = replaceable
				if overflow_action then droppable.dataset.overflow = overflow_action
				droppable.dataset.dropSelector = target_selector
				droppable.dataset.accept = drag_selectors

				addEventListener droppable, 'dragover', onDroppableDragOver
				addEventListener droppable, 'dragenter', onDroppableDragEnter
				addEventListener droppable, 'dragleave', onDroppableDragLeave
				addEventListener droppable, 'drop', onDroppableDrop

			for drag_selector in drag_selectors
				draggables = document.querySelectorAll drag_selector
				for draggable in draggables
					draggable.draggable = true
					draggable.dataset.selector = drag_selector
					disableNestedImageDrag(draggable)
					addEventListener draggable, 'dragstart', onDraggableDragStart
					addEventListener draggable, 'dragend', onDraggableDragEnd

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

	makeRemovable = (el,droppable)->
		if not droppable then droppable = el.parentNode
		if droppable.dataset.removable
			trasher = el.querySelector '.remove'
			if not trasher
				trasher = document.createElement 'div'
				trasher.innerHTML = '&times;'
				trasher.classList.add 'remove'
				el.appendChild trasher
			trasher.addEventListener 'click', onTrashClick

	makeClassable = (el,droppable)->
		if not droppable then droppable = el.parentNode
		if not droppable.dataset.classList then return
		class_object = JSON.parse(droppable.dataset.classList)
		if Array.isArray(class_object)
			class_list = class_object
		else
			class_list = Object.keys(class_object).reduce (res,k)->
				if el.classList.contains(k.replace('.',''))
					console.log class_object[k]
					return class_object[k]
				else
					return null
			,null
		if class_list
			items = el.querySelectorAll '.classes .item'
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

	makeSortable = (el,droppable)->
		if not droppable then droppable = el.parentNode
		if droppable.dataset.sortable
			disableNestedImageDrag el
			el.draggable = true
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

	assignImageNumbers = (section)->
		imgs = section.querySelectorAll 'img'
		for img, i in imgs
			item = parentItem img
			item.dataset.imageNumber = i+1

	highlightPotentials = ->
		droppables = _body.querySelectorAll '[data-drop-selector]'
		for droppable in droppables
			if droppable.dataset.accept.indexOf(_current_drag_selector) isnt -1
				droppable.classList.add 'potential'

	lowlightPotentials = ->
		potentials = _body.querySelectorAll '.potential'
		for potential in potentials
			potential.classList.remove 'potential'

	onDraggableDragStart = (e)->
		that = this
		dt = e.dataTransfer
		_current_draggable = e.target
		_current_drag_selector = that.dataset.selector
		dt.effectAllowed = 'move'
		dt.setData 'source','external'
		if dt.setDragImage
			img = _current_draggable.querySelector 'img'
			if img
				_drag_image.style.backgroundImage = 'url('+img.src+')'
				dt.setDragImage _drag_image,62,62
		that.classList.add 'drag'
		highlightPotentials()
		return false

	onDraggableDragEnd = (e)->
		that = this
		that.classList.remove 'drag'
		_current_draggable = null
		_current_drag_selector = null
		lowlightPotentials()
		return false

	onDroppableDragOver = (e)->
		that = this
		if that.dataset.accept.indexOf(_current_drag_selector) isnt -1
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
		if that.dataset.accept.indexOf(_current_drag_selector) isnt -1
			that.classList.add 'over'
			fireCallbacks('dragenter',e)
		return false

	onDroppableDragLeave = (e)->
		that = this
		_current_drop_selector = null
		that.classList.remove 'over'
		return false

	onDroppableDrop = (e)->
		that = this
		if e.stopPropagation then e.stopPropagation()
		if that.dataset.accept.indexOf(_current_drag_selector) isnt -1
			lowlightPotentials()
			that.classList.remove 'over'
			clone = _current_draggable.cloneNode(true)
			clone.removeAttribute 'draggable'
			clone.classList.remove 'drag'
			itemise clone
			if that.dataset.replaceable
				that.innerHTML = ''
				that.appendChild clone
			else
				makeSortable clone, that
				if e.target is that
					that.appendChild clone
				else
					insertNextTo clone, getSortable(e.target,that)
			if clone_img = clone.querySelector 'img'
				clone_img.onload = ->
					checkOverflow(that,clone,true)
				assignImageNumbers parentSection that
			else
				checkOverflow(that,clone,true)
			makeRemovable clone, that
			makeClassable clone, that
			fireCallbacks('drop',clone)
		else if _is_sorting
			checkOverflow that
			assignImageNumbers parentSection that
			fireCallbacks('drop',_current_draggable)
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
		return el

	onAddPageClick = (e)->
		addPage e.target.parentNode

	addPage = (page)->
		section = page.parentNode
		if page
			new_page = page.cloneNode true
		else
			new_page = _body.querySelector('.page').cloneNode true
		items = new_page.querySelectorAll '[data-item],.add_page'
		for item in items
			item.remove()
		new_page.dataset.repeatable = true
		new_page.dataset.removable = true
		section.insertBefore new_page, page.nextSibling
		addPageFeatures new_page
		refreshPages()
		frameResize()
		applyRules()
		return new_page

	onTrashClick = (e)->
		el = e.target.parentNode
		to_remove = if el.dataset.item then 'item' else 'page'
		sure = confirm 'Are you sure you want to remove the '+to_remove+'?'
		if sure
			if to_remove is 'page'
				items = el.querySelectorAll '[data-item]'
				for item in items
					removeItem item
				el.remove()
				refreshPages()
			else
				removeItem el
			fireCallbacks 'remove', e
			fireCallbacks 'update'

	removeItem = (el)->
		set = _body.querySelectorAll '[data-item="'+el.dataset.item+'"]'
		for set_el in set
			droppable = set_el.parentNode
			set_el.remove()
			checkOverflow droppable, null, true
			assignImageNumbers parentSection droppable

	consolidate = (el)->
		els = _body.querySelectorAll '[data-item="'+el.dataset.item+'"]'
		if els.length > 1
			for set_el in els
				if not set_el.dataset.slave
					set_el.innerHTML = set_el.dataset.content
					addFeatures set_el
					delete set_el.dataset.content
				else
					set_el.remove()

	checkOverflow = (droppable,element,check_all)->
		if _is_sorting or not element
			els = droppable.querySelectorAll '[data-item]'
			for el in els
				el.style.height = 'auto'
				el.style.width = 'auto'
				if not el.dataset.slave then consolidate el
		droppable_height = droppable.offsetHeight
		# Uncomment the conditional if text oveflow is screwed up.
		if droppable.scrollHeight > droppable_height
			console.log 'overflow'
			action = droppable.dataset.overflow
			switch action
				when 'continue'
					# This only applies to texts for now
					last_el = droppable.lastElementChild
					if last_el && droppable.scrollHeight > droppable_height
						removeFeatures last_el
						if last_el.classList.contains('image')
							continuer = last_el
						else
							if not last_el.dataset.slave then last_el.dataset.content = last_el.innerHTML
							continuer = last_el.cloneNode false
							continuer.dataset.slave = true
							l = 20000
							while l-- and droppable.scrollHeight > droppable_height
								lc = last_el.lastChild
								if not lc
									last_el.remove()
									refuseDrop droppable, '[continue] No last child.'
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
							cl = fc.cloneNode false
							last_el.appendChild fc
							cl.textContent = ''
							l = 20000
							if fc.textContent.length > 0
								while l-- and droppable.scrollHeight > droppable_height
									fcText = fc.textContent.split(' ')
									cl.textContent = fcText.pop()+' '+cl.textContent
									fc.textContent = fcText.join(' ')
							continuer.insertBefore cl, continuer.firstChild
						page = parentPage droppable
						drps = page.querySelectorAll '[data-drop-selector="'+droppable.dataset.dropSelector+'"]'
						droppable_index = Array.prototype.indexOf.call drps, droppable
						drp = drps[droppable_index+1]
						if not drp or drp is droppable
							next_page = page.nextElementSibling
							if not next_page or next_page.nodeType isnt 1
								next_page = addPage page
							drp = next_page.querySelector '[data-drop-selector="'+droppable.dataset.dropSelector+'"]'
						drp.insertBefore continuer, drp.firstChild
						if not last_el.dataset.slave then addFeatures last_el
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
					if last_el
						overflow = droppable.scrollHeight - droppable_height
						max_height = last_el.clientHeight - overflow
						if max_height > 0
							max_height_factor = max_height/droppable_height
							max_height_percentage = max_height_factor*100
							# last_el.style.height = max_height_percentage+'%'
							last_el.style.height = (max_height / _mm2px)+'mm'
							fireCallbacks 'update'
						else
							if not _is_sorting and element then element.remove()
							refuseDrop droppable, '[shrinkLast] Max height < 0.'
				when 'shrinkLastWidth'
					last_el = droppable.lastElementChild
					if last_el
						overflow = droppable.scrollHeight - droppable_height
						start_height = last_el.clientHeight
						max_height = start_height - overflow
						l = 100
						last_el.style.width = l+'%'
						while l-- && droppable.scrollHeight > droppable_height && last_el.clientHeight <= start_height
							last_el.style.width = l+'%'
						if l is -1
							if not _is_sorting and element then element.remove()
							refuseDrop droppable, '[shrinkLastWidth] Too big.'
						else
							fireCallbacks 'update'
				else
					if not _is_sorting and element then element.remove()
					refuseDrop droppable, 'Too big for container.'
		else
			fireCallbacks 'update'
		if check_all
			droppables_on_page = parentPage(droppable).querySelectorAll '[data-drop-selector]'
			for dop in droppables_on_page
				if dop isnt droppable
					checkOverflow dop

	refuseDrop = (droppable,msg)->
		if msg then console.error msg
		droppable.classList.add 'nodrop'
		droppable.width = droppable.offsetWidth
		droppable.classList.add 'fade'
		droppable.width = droppable.offsetWidth
		droppable.classList.remove 'nodrop'
		setTimeout ->
			droppable.classList.remove 'fade'
		,2000

	setCallback = (key,callback)->
		if not _callbacks[key] then _callbacks[key] = []
		_callbacks[key].push callback

	parentPage = (el)->
		while not el.classList.contains 'page'
			el = el.parentNode
		return el

	parentSection = (el)->
		while el.nodeName isnt 'SECTION'
			el = el.parentNode
		return el

	parentItem = (el)->
		while not el.dataset.item
			el = el.parentNode
		return el

	getID = ->
		return Math.random().toString(36).substring 8

	fireCallbacks = (key,e)->
		# console.log 'Firing "'+key+'"'
		keys = key.split ' '
		for k in keys
			if _callbacks[k]
				for callback in _callbacks[k]
					callback(e)

	getHTML = (section)->
		lowlightPotentials()
		if section
			clone = _body.querySelector('section[data-id="'+section+'"]').cloneNode true
		else
			clone = _body.querySelector('section').cloneNode true
		removeFeatures clone
		return clone.innerHTML.trim()

	print = (format)->
		print_format = format || _settings.format.print
		onBeforePrint(print_format)
		_frame.contentWindow.print()
		onAfterPrint(print_format)
		return false

	onBeforePrint = (print_format)->
		_frame.contentDocument.body.classList.remove _settings.format.screen
		_frame.contentDocument.body.classList.add print_format

	onAfterPrint = (print_format)->
		_frame.contentDocument.body.classList.remove print_format
		_frame.contentDocument.body.classList.add _settings.format.screen

	init(body,options)

	return {
		frameResize: frameResize
		print: print
		on: setCallback
		get: getHTML
		body: _body
		scrollTo: scrollTo
		scrollToNext: scrollToEl
	}

window.aPRINT = (el,options)->
	if typeof el is 'string'
		el = document.querySelector(el)
		if not el then return false
	return new A(el,options)

Math.easeInOutQuad = (ct,s,c,d)->
	ct /= d/2
	if ct < 1 then return c/2*ct*ct + s
	ct--
	return -c/2 * (ct*(ct-2) - 1) + s