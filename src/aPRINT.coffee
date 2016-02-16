A = (body,options)->
	
	_frame = null
	_body = null
	_sections = null
	_pages = null
	_callbacks = {}
	_current_draggable = null
	_current_drag_selector = null
	_current_sortable_target = null
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
		_body = body
		createIframe()

	createIframe = ->
		_pages = _body.querySelectorAll '.page'
		_frame = document.createElement 'iframe'
		_frame.style.borderWidth = 0
		# _frame.style.overflow = 'hidden'
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
		_frame.contentDocument.body.classList.add _settings.format
		_frame.contentDocument.body.appendChild _body
		refreshPages()
		if typeof _settings.styles is 'string' then _settings.styles = [_settings.styles]
		for stylesheet in _settings.styles
			insertStyle stylesheet
		insertSizer()
		if _settings.editable
			activateContent()
			setupListeners()
		activateKeys()
		frameResize()
		fireCallbacks 'loaded'

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
			addPageFeatures page
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
		mm2px = 3.78
		paper_width = 210
		margin = 24
		max_width = (paper_width + margin) * mm2px
		act_width = _frame.offsetWidth
		factor = act_width / max_width
		# _frame.contentDocument.body.style.transformOrigin = ((margin*2)*factor)+'px 0'
		_frame.contentDocument.body.style.transform = 'scale('+factor+')'
		_frame.contentDocument.body.style.marginLeft = ((act_width - max_width)/2 + margin)+'px'
		_frame.contentDocument.body.style.height = _frame.contentDocument.body.getBoundingClientRect().height
		# console.log _frame.contentDocument.body.getBoundingClientRect().height
		# pageWidth = .9 * _body.offsetWidth
		# a4width = 210
		# a4height = 297
		# a4mm = ((100/a4width)*(pageWidth/100))
		# _frame.contentDocument.querySelector('#sizer').innerHTML = 'html{font-size:'+a4mm+'px}'

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
		adder = document.createElement 'div'
		adder.classList.add 'add_page'
		adder.innerHTML = '+'
		adder.addEventListener 'click', onAddPageClick
		page.appendChild adder
		if page.classList.contains 'removable'
			trasher = page.querySelector '.remove'
			if not trasher
				trasher = document.createElement 'div'
				trasher.innerHTML = '&times;'
				trasher.classList.add 'remove'
				page.appendChild trasher
			trasher.addEventListener 'click', onTrashClick

	setupListeners = ->
		for target,rule of _settings.rules
			applyRule target,rule

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
		e.dataTransfer.effectAllowed = 'move'
		e.dataTransfer.setData 'source','external'
		_current_draggable = e.target
		_current_drag_selector = that.dataset.selector
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
			itemise clone
			if that.dataset.replace
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
			else
				checkOverflow(that,clone,true)
			makeRemovable clone, that
			makeClassable clone, that
		else if _is_sorting
			checkOverflow that
		fireCallbacks 'drop'
		return false

	itemise = (el,sibling)->
		el.dataset.item = if sibling then sibling.dataset.id else getID()

	applyRule = (target,rule)->
		drop_selector = target
		drag_selectors = if typeof rule.accept is 'string' then [rule.accept] else rule.accept

		for drag_selector in drag_selectors
			draggables = document.querySelectorAll drag_selector		
			for draggable in draggables
				draggable.draggable = true
				draggable.dataset.selector = drag_selector
				console.log draggable.dataset.selector = drag_selector
				# if not draggable.dataset.dropSelectors then draggable.dataset.dropSelectors = []
				# draggable.dataset.dropSelectors.push drop_selector
				disableNestedImageDrag(draggable)
				addEventListener draggable, 'dragstart', onDraggableDragStart
				addEventListener draggable, 'dragend', onDraggableDragEnd
		
		droppables = _body.querySelectorAll drop_selector
		replace_on_drop = if typeof rule.replace is 'boolean' then rule.replace else false
		removable = if typeof rule.removable is 'boolean' then rule.removable else true
		sortable = if typeof rule.sortable is 'boolean' then rule.sortable else true
		overflow_action = if rule.overflow then rule.overflow else false
		drop_classes = if rule.classes then rule.classes else false
		for droppable in droppables
			if drop_classes then droppable.dataset.classList = drop_classes
			if removable then droppable.dataset.removable = removable
			if sortable then droppable.dataset.sortable = sortable
			if replace_on_drop then droppable.dataset.replace = true
			if overflow_action then droppable.dataset.overflow = overflow_action
			droppable.dataset.dropSelector = drop_selector
			droppable.dataset.accept = drag_selectors

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

	makeRemovable = (el,droppable)->
		if not droppable then droppable = el.parentNode
		if droppable.dataset.removable
			el.classList.add 'removable'
			trasher = el.querySelector '.remove'
			if not trasher
				trasher = document.createElement 'div'
				trasher.innerHTML = '&times;'
				trasher.classList.add 'remove'
				el.appendChild trasher
			trasher.addEventListener 'click', onTrashClick

	makeClassable = (el,droppable)->
		if not droppable then droppable = el.parentNode
		if droppable.dataset.classList
			el.classList.add 'classable'
			items = el.querySelectorAll '.classes .item'
			class_list = droppable.dataset.classList.split ','
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
		section = page.parentNode
		if page
			new_page = page.cloneNode true
		else
			new_page = _body.querySelector('.page').cloneNode true
		items = new_page.querySelectorAll '[data-item],.add_page'
		for item in items
			item.remove()
		new_page.classList.add 'removable'
		section.insertBefore new_page, page.nextSibling
		addPageFeatures new_page
		refreshPages()
		frameResize()
		setupListeners()
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
			fireCallbacks 'update', e

	removeItem = (el)->
		set = _body.querySelectorAll '[data-item="'+el.dataset.item+'"]'
		for set_el in set
			droppable = set_el.parentNode
			set_el.remove()
			checkOverflow droppable, null, true

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
				if not el.dataset.slave then consolidate el
		if droppable.scrollHeight > droppable.clientHeight
			action = droppable.dataset.overflow
			switch action
				when 'continue'
					# This only applies to texts for now
					last_el = droppable.lastElementChild
					removeFeatures last_el
					last_el.dataset.content = last_el.innerHTML
					continuer = last_el.cloneNode()
					continuer.dataset.slave = true
					l = 20000
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
					l = 20000
					while l-- and droppable.scrollHeight > droppable.clientHeight
						fcHTML = fc.innerHTML.split(' ')
						cl.innerHTML = fcHTML.pop()+' '+cl.innerHTML
						fc.innerHTML = fcHTML.join(' ')
					console.log 'scrollHeight:',droppable.scrollHeight
					console.log 'clientHeight:',droppable.clientHeight
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
						if not _is_sorting and element then element.remove()
						refuseDrop droppable
				else
					if not _is_sorting and element then element.remove()
					refuseDrop droppable
		else
			fireCallbacks 'update'
		if check_all
			droppables_on_page = parentPage(droppable).querySelectorAll '[data-drop-selector]'
			for dop in droppables_on_page
				if dop isnt droppable
					checkOverflow dop

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
		console.log 'Firing "'+key+'"'
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

	print = ->
		_frame.contentWindow.print()

	init(body,options)

	return {
		frameResize: frameResize
		print: print
		on: setCallback
		get: getHTML
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