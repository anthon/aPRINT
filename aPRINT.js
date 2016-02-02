// Generated by CoffeeScript 1.10.0
(function() {
  var A;

  A = function(body, options) {
    var _body, _callbacks, _current_draggable, _current_drop_selector, _current_sortable_target, _frame, _is_sorting, _pages, _sections, _settings, activateContent, activateKeys, addAddPage, addDragDroppable, addEventListener, addFeatures, addPage, checkOverflow, consolidate, createIframe, disableNestedImageDrag, fireCallbacks, frameResize, getHTML, getID, getSortable, init, insertNextTo, insertSizer, insertStyle, itemise, makeClassable, makeRemovable, makeSortable, onAddPageClick, onDraggableDragEnd, onDraggableDragStart, onDroppableDragEnter, onDroppableDragLeave, onDroppableDragOver, onDroppableDrop, onKeyDown, onTrashClick, onWindowResize, parentPage, populateIframe, print, refreshPageNumbers, refuseDrop, removeFeatures, scrollTo, scrollToEl, setCallback, setupListeners;
    _frame = null;
    _body = null;
    _sections = null;
    _pages = null;
    _callbacks = {};
    _current_draggable = null;
    _current_drop_selector = null;
    _current_sortable_target = null;
    _is_sorting = false;
    _settings = {
      styles: ['../aPRINT.css'],
      id: 'aPRINT',
      format: 'A4',
      transparent: false,
      editable: true,
      margins: {
        left: ''
      }
    };
    init = function(body, options) {
      var key, value;
      for (key in options) {
        value = options[key];
        _settings[key] = value;
      }
      _body = body;
      return createIframe();
    };
    createIframe = function() {
      _pages = _body.querySelectorAll('.page');
      _frame = document.createElement('iframe');
      _frame.width = _body.offsetWidth;
      _frame.style.borderWidth = 0;
      if (_settings.transparent) {
        _frame.setAttribute('allowtransparency', true);
      }
      _body.parentNode.insertBefore(_frame, _body);
      window.addEventListener('resize', onWindowResize);
      if (_frame.contentWindow.document.readyState === 'complete') {
        return populateIframe();
      } else {
        return _frame.contentWindow.addEventListener('load', function() {
          return populateIframe();
        });
      }
    };
    populateIframe = function() {
      var i, len, ref, stylesheet;
      _frame.contentDocument.body.classList.add(_settings.format);
      _frame.contentDocument.body.appendChild(_body);
      refreshPageNumbers();
      if (typeof _settings.styles === 'string') {
        _settings.styles = [_settings.styles];
      }
      ref = _settings.styles;
      for (i = 0, len = ref.length; i < len; i++) {
        stylesheet = ref[i];
        insertStyle(stylesheet);
      }
      insertSizer();
      if (_settings.editable) {
        activateContent();
        setupListeners();
      }
      activateKeys();
      return setTimeout(function() {
        return frameResize();
      }, 200);
    };
    insertSizer = function() {
      var sizer;
      sizer = document.createElement('style');
      sizer.id = 'sizer';
      return _frame.contentDocument.head.appendChild(sizer);
    };
    insertStyle = function(style) {
      var styleLink;
      styleLink = document.createElement('link');
      styleLink.type = 'text/css';
      styleLink.rel = 'stylesheet';
      styleLink.href = style;
      return _frame.contentDocument.head.appendChild(styleLink);
    };
    addEventListener = function(el, evt, callback) {
      el.removeEventListener(evt, callback);
      return el.addEventListener(evt, callback);
    };
    activateContent = function() {
      var i, item, items, j, len, len1, page, results;
      items = _body.querySelectorAll('[data-item]');
      for (i = 0, len = _pages.length; i < len; i++) {
        page = _pages[i];
        disableNestedImageDrag(page);
        addAddPage(page);
      }
      results = [];
      for (j = 0, len1 = items.length; j < len1; j++) {
        item = items[j];
        results.push(addFeatures(item));
      }
      return results;
    };
    activateKeys = function() {
      document.addEventListener('keydown', onKeyDown);
      return _frame.contentDocument.addEventListener('keydown', onKeyDown);
    };
    onKeyDown = function(e) {
      switch (e.keyCode) {
        case 80:
          if (e.metaKey) {
            e.preventDefault();
            print();
            return false;
          }
          break;
        case 40:
          if (e.shiftKey) {
            return scrollToEl('section');
          } else {
            return scrollToEl('.page');
          }
          break;
        case 38:
          if (e.shiftKey) {
            return scrollToEl('section', true);
          } else {
            return scrollToEl('.page', true);
          }
      }
    };
    scrollTo = function(target, duration) {
      var animate, change, currentTime, increment, section, section_id, start, target_top;
      if (typeof target === 'string') {
        target = _body.querySelector(target);
      }
      if (target && target.getBoundingClientRect) {
        if (!duration) {
          duration = 200;
        }
        section = target.nodeName === 'SECTION' ? target : target.parentNode;
        section_id = section.dataset.id;
        console.log('section id', section_id);
        body = _frame.contentDocument.body;
        start = body.scrollTop;
        target_top = Math.round(target.getBoundingClientRect().top + start);
        change = target ? target_top - start : 0 - start;
        currentTime = 0;
        increment = 20;
        animate = function() {
          var scrollTop;
          currentTime += increment;
          scrollTop = Math.easeInOutQuad(currentTime, start, change, duration);
          body.scrollTop = scrollTop;
          if (currentTime < duration) {
            return setTimeout(animate, increment);
          }
        };
        animate();
        return fireCallbacks('scroll', section_id);
      }
    };
    scrollToEl = function(selector, reverse) {
      var el, els, i, index, len, r, r_bottom, r_top, wb;
      els = _body.querySelectorAll(selector);
      wb = _frame.contentWindow.innerHeight;
      for (index = i = 0, len = els.length; i < len; index = ++i) {
        el = els[index];
        r = el.getBoundingClientRect();
        r_top = Math.round(r.top);
        r_bottom = Math.round(r.bottom);
        if (reverse) {
          if (r_top >= 0 && r_top <= wb) {
            return scrollTo(els[index - 1]);
          }
          if (r_top <= 0 && r_bottom >= wb) {
            return scrollTo(el);
          }
        } else {
          if (r_top > 0 && r_top < wb) {
            return scrollTo(el);
          }
          if ((r_top === 0 && r_top < wb) || (r_top <= 0 && r_bottom >= wb)) {
            return scrollTo(els[index + 1]);
          }
        }
      }
    };
    onWindowResize = function(e) {
      return frameResize();
    };
    frameResize = function() {
      var act_widh, factor, margin, max_width, mm2px, paper_width;
      mm2px = 3.78;
      paper_width = 210;
      margin = 24;
      max_width = (paper_width + margin) * mm2px;
      act_widh = _frame.offsetWidth;
      factor = act_widh / max_width;
      _frame.contentDocument.body.style.transformOrigin = '48px 0';
      return _frame.contentDocument.body.style.transform = 'scale(' + factor + ')';
    };
    refreshPageNumbers = function() {
      var i, len, page, pages, results, section, seq;
      _sections = _body.querySelectorAll('section');
      results = [];
      for (i = 0, len = _sections.length; i < len; i++) {
        section = _sections[i];
        pages = section.querySelectorAll('.page');
        seq = 'odd';
        results.push((function() {
          var j, len1, results1;
          results1 = [];
          for (j = 0, len1 = pages.length; j < len1; j++) {
            page = pages[j];
            page.classList.remove('even', 'odd');
            page.classList.add(seq);
            results1.push(seq = seq === 'odd' ? 'even' : 'odd');
          }
          return results1;
        })());
      }
      return results;
    };
    addAddPage = function(page) {
      var adder;
      adder = document.createElement('div');
      adder.classList.add('add_page');
      adder.innerHTML = '+';
      adder.addEventListener('click', onAddPageClick);
      return page.appendChild(adder);
    };
    setupListeners = function() {
      var drag, drop, ref, results;
      ref = _settings.rules;
      results = [];
      for (drag in ref) {
        drop = ref[drag];
        results.push(addDragDroppable(drag, drop));
      }
      return results;
    };
    onDraggableDragStart = function(e) {
      var that;
      that = this;
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('source', 'external');
      _current_draggable = e.target;
      _current_drop_selector = that.dataset.dropSelector;
      that.classList.add('drag');
      return false;
    };
    onDraggableDragEnd = function(e) {
      var that;
      that = this;
      that.classList.remove('drag');
      _current_draggable = null;
      _current_drop_selector = null;
      return false;
    };
    onDroppableDragOver = function(e) {
      var that;
      that = this;
      if (_current_drop_selector === that.dataset.dropSelector) {
        if (e.preventDefault) {
          e.preventDefault();
        }
        e.dataTransfer.dropEffect = 'move';
        that.classList.add('over');
        fireCallbacks('dragover', e);
      } else if (_is_sorting) {
        if (e.preventDefault) {
          e.preventDefault();
        }
        _current_draggable.style.opacity = 0;
        if (e.target === that) {
          insertNextTo(_current_draggable, that.lastChild);
        } else if (_current_sortable_target !== _current_draggable) {
          insertNextTo(_current_draggable, getSortable(e.target, that));
        }
        fireCallbacks('dragover', e);
      }
      return false;
    };
    onDroppableDragEnter = function(e) {
      var that;
      that = this;
      if (_current_drop_selector === that.dataset.dropSelector) {
        that.classList.add('over');
        fireCallbacks('dragenter', e);
      }
      return false;
    };
    onDroppableDragLeave = function(e) {
      var that;
      that = this;
      that.classList.remove('over');
      return false;
    };
    onDroppableDrop = function(e) {
      var clone, clone_img, that;
      that = this;
      if (e.stopPropagation) {
        e.stopPropagation();
      }
      if (_current_drop_selector === that.dataset.dropSelector) {
        that.classList.remove('over');
        clone = _current_draggable.cloneNode(true);
        clone.removeAttribute('draggable');
        itemise(clone);
        if (that.dataset.replace) {
          that.innerHTML = '';
          that.appendChild(clone);
        } else {
          makeSortable(clone);
          if (e.target === that) {
            that.appendChild(clone);
          } else {
            insertNextTo(clone, getSortable(e.target, that));
          }
        }
        if (clone_img = clone.querySelector('img')) {
          clone_img.onload = function() {
            return checkOverflow(that, clone, true);
          };
        } else {
          checkOverflow(that, clone, true);
        }
        makeRemovable(clone);
        makeClassable(clone);
      } else if (_is_sorting) {
        checkOverflow(that);
      }
      fireCallbacks('drop');
      return false;
    };
    itemise = function(el, sibling) {
      return el.dataset.item = sibling ? sibling.dataset.id : getID();
    };
    addDragDroppable = function(drag, drop) {
      var drag_selector, draggable, draggables, drop_classes, drop_selector, droppable, droppables, i, j, len, len1, overflow_action, removable, replace_on_drop, results, sortable;
      drag_selector = drag;
      if (typeof drop === 'string') {
        drop_selector = drop;
      } else if (drop.target) {
        drop_selector = drop.target;
      }
      replace_on_drop = typeof drop.replace === 'boolean' ? drop.replace : false;
      removable = typeof drop.removable === 'boolean' ? drop.removable : true;
      sortable = typeof drop.sortable === 'boolean' ? drop.sortable : true;
      overflow_action = drop.overflow ? drop.overflow : false;
      drop_classes = drop.classes ? drop.classes : false;
      draggables = document.querySelectorAll(drag_selector);
      droppables = _body.querySelectorAll(drop_selector);
      for (i = 0, len = draggables.length; i < len; i++) {
        draggable = draggables[i];
        draggable.draggable = true;
        if (drop_classes) {
          draggable.dataset.classList = drop_classes;
        }
        if (removable) {
          draggable.dataset.removable = removable;
        }
        if (sortable) {
          draggable.dataset.sortable = sortable;
        }
        draggable.dataset.dropSelector = drop_selector;
        disableNestedImageDrag(draggable);
        addEventListener(draggable, 'dragstart', onDraggableDragStart);
        addEventListener(draggable, 'dragend', onDraggableDragEnd);
      }
      results = [];
      for (j = 0, len1 = droppables.length; j < len1; j++) {
        droppable = droppables[j];
        droppable.dataset.dropSelector = drop_selector;
        droppable.dataset.overflowAction = overflow_action;
        if (replace_on_drop) {
          droppable.dataset.replace = true;
        }
        addEventListener(droppable, 'dragover', onDroppableDragOver);
        addEventListener(droppable, 'dragenter', onDroppableDragEnter);
        addEventListener(droppable, 'dragleave', onDroppableDragLeave);
        results.push(addEventListener(droppable, 'drop', onDroppableDrop));
      }
      return results;
    };
    disableNestedImageDrag = function(el) {
      var i, image, images_in_draggable, len, results;
      images_in_draggable = el.querySelectorAll('img');
      results = [];
      for (i = 0, len = images_in_draggable.length; i < len; i++) {
        image = images_in_draggable[i];
        image.draggable = false;
        image.style['user-drag'] = 'none';
        image.style['-moz-user-select'] = 'none';
        results.push(image.style['-webkit-user-drag'] = 'none');
      }
      return results;
    };
    addFeatures = function(el) {
      makeSortable(el);
      makeRemovable(el);
      return makeClassable(el);
    };
    makeRemovable = function(el) {
      var trasher;
      if (el.dataset.removable) {
        el.classList.add('removable');
        trasher = el.querySelector('.remove');
        if (!trasher) {
          trasher = document.createElement('div');
          trasher.innerHTML = '&times;';
          trasher.classList.add('remove');
          el.appendChild(trasher);
        }
        return trasher.addEventListener('click', onTrashClick);
      }
    };
    makeClassable = function(el) {
      var class_list, cls, container, expander, i, item, items, j, len, len1, list, results;
      if (el.dataset.classList) {
        el.classList.add('classable');
        items = el.querySelectorAll('.classes .item');
        class_list = el.dataset.classList.split(',');
        if (items.length === 0) {
          container = document.createElement('div');
          container.classList.add('classes');
          expander = document.createElement('div');
          expander.classList.add('expander');
          expander.innerHTML = '&bull;';
          container.appendChild(expander);
          list = document.createElement('div');
          list.classList.add('list');
          class_list.unshift('none');
          for (i = 0, len = class_list.length; i < len; i++) {
            cls = class_list[i];
            item = document.createElement('div');
            item.classList.add('item');
            item.innerHTML = cls;
            list.appendChild(item);
          }
          items = list.querySelectorAll('.item');
          container.appendChild(list);
          el.appendChild(container);
        }
        results = [];
        for (j = 0, len1 = items.length; j < len1; j++) {
          item = items[j];
          results.push(item.addEventListener('click', function(e) {
            var len2, len3, m, n, results1, set, set_el;
            set = _body.querySelectorAll('[data-item="' + el.dataset.item + '"]');
            results1 = [];
            for (m = 0, len2 = set.length; m < len2; m++) {
              set_el = set[m];
              for (n = 0, len3 = class_list.length; n < len3; n++) {
                cls = class_list[n];
                set_el.classList.remove(cls);
              }
              set_el.classList.add(this.innerHTML);
              results1.push(checkOverflow(set_el.parentNode));
            }
            return results1;
          }));
        }
        return results;
      }
    };
    makeSortable = function(el) {
      if (el.dataset.sortable) {
        disableNestedImageDrag(el);
        el.draggable = true;
        el.classList.add('sortable');
        el.addEventListener('dragstart', function(e) {
          e.dataTransfer.dropEffect = 'move';
          e.dataTransfer.effectAllowed = 'move';
          e.dataTransfer.setData('source', 'internal');
          _current_draggable = e.target;
          _current_draggable.classList.add('drag');
          _is_sorting = true;
          return false;
        });
        el.addEventListener('dragend', function(e) {
          if (_current_draggable) {
            _current_draggable.classList.remove('drag');
            _current_draggable.style.opacity = 1;
            checkOverflow(e.target.parentNode);
            _current_draggable = null;
            _is_sorting = false;
            return false;
          }
        });
        return el.addEventListener('dragover', function(e) {
          _current_sortable_target = el;
          return consolidate(_current_sortable_target);
        });
      }
    };
    removeFeatures = function(el) {
      var i, len, results, to_remove, to_removes;
      to_removes = el.querySelectorAll('.add_page, .classes, .remove');
      results = [];
      for (i = 0, len = to_removes.length; i < len; i++) {
        to_remove = to_removes[i];
        results.push(to_remove.remove());
      }
      return results;
    };
    insertNextTo = function(el, sibling) {
      var el_index, parent, sibling_index, siblings;
      parent = sibling.parentNode;
      if (el.parentNode === parent) {
        siblings = parent.childNodes;
        el_index = Array.prototype.indexOf.call(siblings, el);
        sibling_index = Array.prototype.indexOf.call(siblings, sibling);
        if (el_index > sibling_index) {
          return parent.insertBefore(el, sibling);
        } else {
          return parent.insertBefore(el, sibling.nextSibling);
        }
      } else {
        return parent.insertBefore(el, sibling);
      }
    };
    getSortable = function(el, parent) {
      var el_parent;
      while (true) {
        el_parent = el.parentNode;
        if (el_parent === parent) {
          break;
        }
        el = el_parent;
      }
      return el;
    };
    onAddPageClick = function(e) {
      return addPage(e.target.parentNode);
    };
    addPage = function(page) {
      var i, item, items, len, new_page, section;
      section = page.parentNode;
      if (page) {
        new_page = page.cloneNode(true);
      } else {
        new_page = _body.querySelector('.page').cloneNode(true);
      }
      items = new_page.querySelectorAll('[data-item],.add_page');
      for (i = 0, len = items.length; i < len; i++) {
        item = items[i];
        item.remove();
      }
      section.insertBefore(new_page, page.nextSibling);
      addAddPage(new_page);
      refreshPageNumbers();
      frameResize();
      setupListeners();
      return new_page;
    };
    onTrashClick = function(e) {
      var droppable, el, i, len, set, set_el;
      el = e.target.parentNode;
      set = _body.querySelectorAll('[data-item="' + el.dataset.item + '"]');
      for (i = 0, len = set.length; i < len; i++) {
        set_el = set[i];
        droppable = set_el.parentNode;
        set_el.remove();
        checkOverflow(droppable, null, true);
      }
      return fireCallbacks('remove', e);
    };
    consolidate = function(el) {
      var els, i, len, results, set_el;
      els = _body.querySelectorAll('[data-item="' + el.dataset.item + '"]');
      if (els.length > 1) {
        results = [];
        for (i = 0, len = els.length; i < len; i++) {
          set_el = els[i];
          if (set_el === el) {
            set_el.innerHTML = set_el.dataset.content;
            addFeatures(set_el);
            results.push(delete set_el.dataset.content);
          } else {
            results.push(set_el.remove());
          }
        }
        return results;
      }
    };
    checkOverflow = function(droppable, element, check_all) {
      var action, cl, continuer, dop, droppables_on_page, drp, el, els, fc, fcHTML, i, j, l, last_el, lc, len, len1, len2, m, max_height, max_height_percentage, next_page, overflow, page, results;
      if (_is_sorting || !element) {
        els = droppable.querySelectorAll('[data-item]');
        for (i = 0, len = els.length; i < len; i++) {
          el = els[i];
          el.style.height = 'auto';
        }
      }
      if (droppable.scrollHeight > droppable.clientHeight) {
        action = droppable.dataset.overflowAction;
        switch (action) {
          case 'continue':
            last_el = droppable.lastElementChild;
            removeFeatures(last_el);
            last_el.dataset.content = last_el.innerHTML;
            continuer = last_el.cloneNode();
            l = 200;
            while (l-- && droppable.scrollHeight > droppable.clientHeight) {
              lc = last_el.lastChild;
              if (!lc) {
                last_el.remove();
                refuseDrop(droppable);
                return false;
              }
              switch (lc.nodeType) {
                case 1:
                  continuer.insertBefore(lc, continuer.firstChild);
                  break;
                case 3:
                  if (/\S/.test(lc.nodeValue)) {

                  } else {
                    lc.remove();
                  }
                  break;
              }
            }
            fc = continuer.firstChild;
            cl = fc.cloneNode();
            last_el.appendChild(fc);
            cl.innerHTML = '';
            l = 200;
            while (l-- && droppable.scrollHeight > droppable.clientHeight) {
              fcHTML = fc.innerHTML.split(' ');
              cl.innerHTML = fcHTML.pop() + ' ' + cl.innerHTML;
              fc.innerHTML = fcHTML.join(' ');
            }
            continuer.insertBefore(cl, continuer.firstChild);
            page = parentPage(droppable);
            drp = page.querySelector('[data-drop-selector="' + droppable.dataset.dropSelector + '"]');
            if (!drop) {
              next_page = page.nextElementSibling;
              if (!next_page || next_page.nodeType !== 1) {
                next_page = addPage(page);
              }
              drp = next_page.querySelector('[data-drop-selector="' + droppable.dataset.dropSelector + '"]');
            }
            drp.insertBefore(continuer, drp.firstChild);
            addFeatures(last_el);
            checkOverflow(drp);
            fireCallbacks('update');
            break;
          case 'shrinkAll':
            els = droppable.querySelectorAll('.removable');
            l = els.length;
            for (j = 0, len1 = els.length; j < len1; j++) {
              el = els[j];
              el.style.maxHeight = (100 / l) + '%';
            }
            fireCallbacks('update');
            break;
          case 'shrinkLast':
            last_el = droppable.lastElementChild;
            overflow = droppable.scrollHeight - droppable.clientHeight;
            max_height = last_el.clientHeight - overflow;
            max_height_percentage = (max_height / droppable.clientHeight) * 100;
            if (max_height_percentage > 1) {
              last_el.style.height = max_height_percentage + '%';
              fireCallbacks('update');
            } else {
              if (!_is_sorting && element) {
                element.remove();
              }
              refuseDrop(droppable);
            }
            break;
          default:
            if (!_is_sorting && element) {
              element.remove();
            }
            refuseDrop(droppable);
        }
      } else {
        fireCallbacks('update');
      }
      if (check_all) {
        droppables_on_page = parentPage(droppable).querySelectorAll('[data-drop-selector]');
        results = [];
        for (m = 0, len2 = droppables_on_page.length; m < len2; m++) {
          dop = droppables_on_page[m];
          if (dop !== droppable) {
            results.push(checkOverflow(dop));
          } else {
            results.push(void 0);
          }
        }
        return results;
      }
    };
    refuseDrop = function(droppable) {
      droppable.classList.add('nodrop');
      droppable.offsetWidth = droppable.offsetWidth;
      droppable.classList.add('fade');
      droppable.offsetWidth = droppable.offsetWidth;
      droppable.classList.remove('nodrop');
      return setTimeout(function() {
        return droppable.classList.remove('fade');
      }, 1000);
    };
    setCallback = function(key, callback) {
      if (!_callbacks[key]) {
        _callbacks[key] = [];
      }
      return _callbacks[key].push(callback);
    };
    parentPage = function(el) {
      while (!el.classList.contains('page')) {
        el = el.parentNode;
      }
      return el;
    };
    getID = function() {
      return Math.random().toString(36).substring(8);
    };
    fireCallbacks = function(key, e) {
      var callback, i, k, keys, len, results;
      keys = key.split(' ');
      results = [];
      for (i = 0, len = keys.length; i < len; i++) {
        k = keys[i];
        if (_callbacks[k]) {
          results.push((function() {
            var j, len1, ref, results1;
            ref = _callbacks[k];
            results1 = [];
            for (j = 0, len1 = ref.length; j < len1; j++) {
              callback = ref[j];
              results1.push(callback(e));
            }
            return results1;
          })());
        } else {
          results.push(void 0);
        }
      }
      return results;
    };
    getHTML = function(section) {
      var clone;
      if (section) {
        clone = _body.querySelector('section[data-id="' + section + '"]').cloneNode(true);
      } else {
        clone = _body.querySelector('section').cloneNode(true);
      }
      removeFeatures(clone);
      return clone.innerHTML.trim();
    };
    print = function() {
      return _frame.contentWindow.print();
    };
    init(body, options);
    return {
      frameResize: frameResize,
      print: print,
      on: setCallback,
      get: getHTML,
      scrollTo: scrollTo,
      scrollToNext: scrollToEl
    };
  };

  window.aPRINT = function(el, options) {
    if (typeof el === 'string') {
      el = document.querySelector(el);
      if (!el) {
        return false;
      }
    }
    return new A(el, options);
  };

  Math.easeInOutQuad = function(ct, s, c, d) {
    ct /= d / 2;
    if (ct < 1) {
      return c / 2 * ct * ct + s;
    }
    ct--;
    return -c / 2 * (ct * (ct - 2) - 1) + s;
  };

}).call(this);
