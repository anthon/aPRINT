A = (selector,options)->
	
	_frame = null
	_body = null
	_pages = null
	_callbacks = {}
	_current_draggable = null
	_current_drop_selector = null
	_current_sortable_target = null
	_is_sorting = false
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
					  cursor: pointer;
					  background-color: #fff;
					  color: #000;
					  position: absolute;
					  top: 6px;
					  right: 6px;
					  width: 25px;
					  height: 25px;
					  font-size: 13px;
					  line-height: 24px;
					  text-align: center;
					  font-weight: 100;
					}
					body .removable .remove a {
					  color: #000;
					}
					body .removable .remove:hover {
					  background-color: #c20000;
					  color: #fff;
					}
					body .removable .remove:hover a {
					  color: #fff;
					}
					body .removable .remove.active {
					  background-color: #c20000;
					  color: #fff;
					}
					body .removable .remove.active a {
					  color: #fff;
					}
					body .nodrop {
					  background: #f00;
					}
					body .fade {
					  transition: background 0.8s;
					}
					body .classable .classes {
					  position: absolute;
					  top: 6px;
					  left: 6px;
					  text-align: left;
					}
					body .classable .classes .expander {
					  cursor: pointer;
					  background-color: #fff;
					  color: #000;
					  width: 25px;
					  height: 25px;
					  line-height: 28px;
					  text-align: center;
					}
					body .classable .classes .expander a {
					  color: #000;
					}
					body .classable .classes .expander:hover {
					  background-color: #c20000;
					  color: #fff;
					}
					body .classable .classes .expander:hover a {
					  color: #fff;
					}
					body .classable .classes .expander.active {
					  background-color: #c20000;
					  color: #fff;
					}
					body .classable .classes .expander.active a {
					  color: #fff;
					}
					body .classable .classes .list {
					  display: none;
					}
					body .classable .classes .list .item {
					  cursor: pointer;
					  background-color: #fff;
					  color: #000;
					  padding: 6px 8px;
					}
					body .classable .classes .list .item a {
					  color: #000;
					}
					body .classable .classes .list .item:hover {
					  background-color: #000;
					  color: #fff;
					}
					body .classable .classes .list .item:hover a {
					  color: #fff;
					}
					body .classable .classes .list .item.active {
					  background-color: #000;
					  color: #fff;
					}
					body .classable .classes .list .item.active a {
					  color: #fff;
					}
					body .classable .classes:hover .expander {
					  display: none;
					}
					body .classable .classes:hover .list {
					  display: block;
					}
					body .page {
					  background: #fff;
					  width: 90vw;
					  margin: 4rem auto 48px;
					  box-shadow: 0 0 4px 1px rgba(0,0,0,0.24);
					}
					body .page .add_page {
					  cursor: pointer;
					  background-color: rgba(255,255,255,0.12);
					  color: #000;
					  position: relative;
					  bottom: -12px;
					  width: 60%;
					  margin: 0 auto;
					  font-size: 18px;
					  line-height: 1.4;
					  text-align: center;
					}
					body .page .add_page a {
					  color: #000;
					}
					body .page .add_page:hover {
					  background-color: #fff;
					  color: #000;
					}
					body .page .add_page:hover a {
					  color: #000;
					}
					body .page .add_page.active {
					  background-color: #fff;
					  color: #000;
					}
					body .page .add_page.active a {
					  color: #000;
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

	createIframe = ->
		_body = document.querySelector selector
		_frame = document.createElement 'iframe'
		_frame.width = _body.offsetWidth
		_frame.height = _body.offsetHeight
		# _frame.style.borderWidth = 0
		# _frame.style.resize = 'horizontal'
		# _frame.src = 'about:blank'
		_body.parentNode.insertBefore _frame, _body
		if _frame.contentWindow.document.readyState is 'complete'
			populateIframe()
		else
			_frame.contentWindow.addEventListener 'load', ->
				populateIframe()

	populateIframe = ->
		_frame.contentDocument.body.appendChild _body
		if _settings.baseStyle
			insertStyle _settings.baseStyle, true
		else
			insertStyle _baseStyle
		if _settings.stylesheet then insertStyle _settings.stylesheet, true
		activateContent()
		setupListeners()

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
		_pages = _body.querySelectorAll '.page'
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

	addAddPage = (page)->
		adder = document.createElement 'div'
		adder.classList.add 'add_page'
		adder.innerHTML = '+'
		adder.addEventListener 'click', ->
			addPage page
		page.appendChild adder

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
		overflow_action = if drop.overflow then drop.overflow else false
		drop_classes = if drop.classes then drop.classes else false
		draggables = document.querySelectorAll drag_selector
		droppables = _body.querySelectorAll drop_selector
		
		for draggable in draggables
			draggable.draggable = true
			disableNestedImageDrag(draggable)
			draggable.addEventListener 'dragstart', (e)->
				e.dataTransfer.effectAllowed = 'move'
				e.dataTransfer.setData 'source','external'
				_current_draggable = e.target
				_current_drop_selector = drop_selector
				draggable.classList.add 'drag'
				return false
			draggable.addEventListener 'dragend', (e)->
				draggable.classList.remove 'drag'
				_current_draggable = null
				_current_drop_selector = null
				return false
		
		for droppable in droppables
			droppable.dataset.overflowAction = overflow_action
			droppable.addEventListener 'dragover', (e)->
				if _current_drop_selector is drop_selector
					if e.preventDefault then e.preventDefault()
					e.dataTransfer.dropEffect = 'move'
					droppable.classList.add 'over'
					fireCallbacks('dragover',e)
				else if _is_sorting
					if e.preventDefault then e.preventDefault()
					_current_draggable.style.opacity = 0
					if e.target is droppable
						insertNextTo _current_draggable, droppable.lastChild
					else if _current_sortable_target isnt _current_draggable
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
					if drop_classes then clone.dataset.classList = drop_classes
					makeRemovable clone
					makeClassable clone
					if replace_on_drop
						droppable.innerHTML = ''
						droppable.appendChild clone
					else
						makeSortable clone
						if e.target is droppable
							droppable.appendChild clone
						else
							insertNextTo clone, getSortable(e.target,droppable)
					if clone_img = clone.querySelector 'img'
						clone_img.onload = ->
							checkOverflow(droppable,clone)
					else
						checkOverflow(droppable,clone)
					fireCallbacks 'drop'
				return false

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

	addPage = (page)->
		if not page then page = _body.lastChild
		new_page = _body.querySelector('.page').cloneNode true
		removables = new_page.querySelectorAll '.removable'
		for removable in removables
			removable.remove()
		_body.insertBefore new_page, page.nextSibling
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
		if page and typeof page is 'Integer' then return _pages[page].innerHTML
		return _body.innerHTML

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