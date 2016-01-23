// Generated by CoffeeScript 1.10.0
(function() {
  var A;

  A = function(body, options) {
    var _body, _callbacks, _current_draggable, _current_drop_selector, _current_sortable_target, _frame, _is_sorting, _pages, _settings, activateContent, addAddPage, addDragDroppable, addEventListener, addPage, checkOverflow, createIframe, disableNestedImageDrag, fireCallbacks, frameResize, getHTML, getSortable, init, insertNextTo, insertStyle, makeClassable, makeRemovable, makeSortable, onDraggableDragEnd, onDraggableDragStart, onDroppableDragEnter, onDroppableDragLeave, onDroppableDragOver, onDroppableDrop, onTrashClick, onWindowResize, populateIframe, print, refuseDrop, setCallback, setupListeners;
    _frame = null;
    _body = null;
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
      _frame.style.resize = 'horizontal';
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
      _frame.contentDocument.body.appendChild(_body);
      if (typeof _settings.styles === 'string') {
        _settings.styles = [_settings.styles];
      }
      ref = _settings.styles;
      for (i = 0, len = ref.length; i < len; i++) {
        stylesheet = ref[i];
        insertStyle(stylesheet);
      }
      activateContent();
      setupListeners();
      return frameResize();
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
      var classable, classables, i, j, len, len1, len2, len3, m, n, page, removable, removables, results, sortable, sortables;
      sortables = _body.querySelectorAll('.sortable');
      removables = _body.querySelectorAll('.removable');
      classables = _body.querySelectorAll('.classable');
      for (i = 0, len = _pages.length; i < len; i++) {
        page = _pages[i];
        disableNestedImageDrag(page);
        addAddPage(page);
      }
      for (j = 0, len1 = sortables.length; j < len1; j++) {
        sortable = sortables[j];
        disableNestedImageDrag(sortable);
        makeSortable(sortable);
      }
      for (m = 0, len2 = removables.length; m < len2; m++) {
        removable = removables[m];
        makeRemovable(removable);
      }
      results = [];
      for (n = 0, len3 = classables.length; n < len3; n++) {
        classable = classables[n];
        console.log(classable);
        results.push(makeClassable(classable));
      }
      return results;
    };
    onWindowResize = function(e) {
      return frameResize();
    };
    frameResize = function() {
      return _frame.height = _frame.contentDocument.body.offsetHeight;
    };
    addAddPage = function(page) {
      var adder;
      adder = document.createElement('div');
      adder.classList.add('add_page');
      adder.innerHTML = '+';
      adder.addEventListener('click', addPage);
      return _body.insertBefore(adder, page.nextSibling);
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
        makeRemovable(clone);
        makeClassable(clone);
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
            return checkOverflow(that, clone);
          };
        } else {
          checkOverflow(that, clone);
        }
        fireCallbacks('drop');
      }
      return false;
    };
    addDragDroppable = function(drag, drop) {
      var drag_selector, draggable, draggables, drop_classes, drop_selector, droppable, droppables, i, j, len, len1, overflow_action, replace_on_drop, results;
      drag_selector = drag;
      if (typeof drop === 'string') {
        drop_selector = drop;
      } else if (drop.target) {
        drop_selector = drop.target;
      }
      replace_on_drop = typeof drop.replace === 'boolean' ? drop.replace : false;
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
    makeRemovable = function(el) {
      var trasher;
      el.classList.add('removable');
      trasher = el.querySelector('.remove');
      if (!trasher) {
        trasher = document.createElement('div');
        trasher.innerHTML = '&times;';
        trasher.classList.add('remove');
        el.appendChild(trasher);
      }
      return trasher.addEventListener('click', onTrashClick);
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
            var len2, m;
            for (m = 0, len2 = class_list.length; m < len2; m++) {
              cls = class_list[m];
              el.classList.remove(cls);
            }
            el.classList.add(this.innerHTML);
            return checkOverflow(el.parentNode);
          }));
        }
        return results;
      }
    };
    makeSortable = function(el) {
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
        _current_draggable.classList.remove('drag');
        _current_draggable.style.opacity = 1;
        checkOverflow(e.target.parentNode);
        _current_draggable = null;
        _is_sorting = false;
        return false;
      });
      return el.addEventListener('dragover', function(e) {
        return _current_sortable_target = el;
      });
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
    addPage = function(e) {
      var i, len, new_page, page, removable, removables, that;
      that = this;
      page = that.previousSibling;
      new_page = _body.querySelector('.page').cloneNode(true);
      removables = new_page.querySelectorAll('.removable');
      for (i = 0, len = removables.length; i < len; i++) {
        removable = removables[i];
        removable.remove();
      }
      _body.insertBefore(new_page, that.nextSibling);
      addAddPage(new_page);
      frameResize();
      return setupListeners();
    };
    onTrashClick = function(e) {
      var droppable, el;
      el = e.target.parentNode;
      droppable = el.parentNode;
      el.remove();
      checkOverflow(droppable);
      return fireCallbacks('remove', e);
    };
    checkOverflow = function(droppable, element) {
      var action, el, els, i, j, l, last_el, len, len1, max_height, max_height_percentage, overflow;
      if (_is_sorting || !element) {
        els = droppable.querySelectorAll('.removable');
        for (i = 0, len = els.length; i < len; i++) {
          el = els[i];
          el.style.height = 'auto';
        }
      }
      if (droppable.scrollHeight > droppable.clientHeight) {
        action = droppable.dataset.overflowAction;
        switch (action) {
          case 'shrinkAll':
            els = droppable.querySelectorAll('.removable');
            l = els.length;
            for (j = 0, len1 = els.length; j < len1; j++) {
              el = els[j];
              el.style.maxHeight = (100 / l) + '%';
            }
            return fireCallbacks('update');
          case 'shrinkLast':
            last_el = droppable.lastElementChild;
            overflow = droppable.scrollHeight - droppable.clientHeight;
            max_height = last_el.clientHeight - overflow;
            max_height_percentage = (max_height / droppable.clientHeight) * 100;
            console.log(max_height_percentage);
            if (max_height_percentage > 1) {
              last_el.style.height = max_height_percentage + '%';
              return fireCallbacks('update');
            } else {
              if (!_is_sorting) {
                element.remove();
              }
              return refuseDrop(droppable);
            }
            break;
          default:
            if (!_is_sorting) {
              element.remove();
            }
            return refuseDrop(droppable);
        }
      } else {
        return fireCallbacks('update');
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
    getHTML = function(page) {
      var clone, i, len, to_remove, to_removes;
      if (page && typeof page === 'Integer') {
        clone = _pages[page].cloneNode(true);
      } else {
        clone = _body.cloneNode(true);
      }
      console.log(clone);
      to_removes = clone.querySelectorAll('.add_page, .classes, .remove');
      for (i = 0, len = to_removes.length; i < len; i++) {
        to_remove = to_removes[i];
        to_remove.remove();
      }
      return clone.innerHTML;
    };
    print = function() {};
    init(body, options);
    return {
      print: print,
      on: setCallback,
      get: getHTML
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

}).call(this);
