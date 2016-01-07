// Generated by CoffeeScript 1.10.0
(function() {
  var A;

  A = function(selector, options) {
    var _baseStyle, _body, _callbacks, _current_draggable, _current_drop_selector, _frame, _pages, _settings, activateContent, addDragDroppable, createIframe, disableNestedImageDrag, fireCallbacks, getHTML, getSortable, init, insertNextTo, insertStyle, makeRemovable, makeSortable, onOverflow, onTrashClick, print, setCallback, setupListeners;
    _frame = null;
    _body = null;
    _pages = null;
    _callbacks = {};
    _current_draggable = null;
    _current_drop_selector = null;
    _baseStyle = '* { -webkit-box-sizing: border-box; -moz-box-sizing: border-box; -ms-box-sizing: border-box; -o-box-sizing: border-box; box-sizing: border-box; margin: 0; padding: 0; outline: none; } html { font-size: 0.428571428571429vw; } body { background: #808080; } body .over { background: #94ff94; } body .removable { position: relative; } body .removable .remove { font-family: sans-serif; background: #fff; position: absolute; top: 6px; right: 6px; padding: 3px 7px; font-size: 13px; font-weight: 100; color: #000; cursor: pointer; } body .removable .remove:hover { background: #c20000; color: #fff; } body .page { background: #fff; width: 90vw; margin: 4rem auto; } body .page.A4 { height: 127.28571428571429vw; } @media print { html { font-size: 4.2333336mm; } html body .page.A4 { width: 210mm; height: 297mm; } }';
    _settings = {
      stylesheet: null,
      id: 'aPRINT',
      format: 'A4'
    };
    init = function(selector, options) {
      var key, value;
      for (key in options) {
        value = options[key];
        _settings[key] = value;
      }
      createIframe();
      activateContent();
      return setupListeners();
    };
    createIframe = function() {
      _body = document.querySelector(selector);
      _frame = document.createElement('iframe');
      _frame.width = _body.offsetWidth;
      _frame.height = _body.offsetHeight;
      _frame.style.resize = 'horizontal';
      _body.parentNode.insertBefore(_frame, _body);
      _frame.contentDocument.body.appendChild(_body);
      if (_settings.baseStyle) {
        insertStyle(_settings.baseStyle, true);
      } else {
        insertStyle(_baseStyle);
      }
      if (_settings.stylesheet) {
        return insertStyle(_settings.stylesheet, true);
      }
    };
    insertStyle = function(style, is_link) {
      var styleLink, styleTag;
      if (is_link) {
        styleLink = document.createElement('link');
        styleLink.type = 'text/css';
        styleLink.rel = 'stylesheet';
        styleLink.href = style;
        return _frame.contentDocument.head.appendChild(styleLink);
      } else {
        styleTag = document.createElement('style');
        styleTag.innerHTML = style;
        return _frame.contentDocument.head.appendChild(styleTag);
      }
    };
    activateContent = function() {
      var i, j, len, len1, len2, m, page, removable, removables, results, sortable, sortables;
      _pages = _body.querySelectorAll('.page');
      sortables = _body.querySelectorAll('.sortable');
      removables = _body.querySelectorAll('.removable');
      for (i = 0, len = _pages.length; i < len; i++) {
        page = _pages[i];
        disableNestedImageDrag(page);
        makeSortable(page);
      }
      for (j = 0, len1 = sortables.length; j < len1; j++) {
        sortable = sortables[j];
        disableNestedImageDrag(sortable);
        makeSortable(sortable);
      }
      results = [];
      for (m = 0, len2 = removables.length; m < len2; m++) {
        removable = removables[m];
        results.push(makeRemovable(removable));
      }
      return results;
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
    addDragDroppable = function(drag, drop) {
      var drag_selector, draggable, draggables, drop_selector, droppable, droppables, i, j, len, len1, overflow_action, replace_on_drop, results;
      drag_selector = drag;
      if (typeof drop === 'string') {
        drop_selector = drop;
      } else if (drop.target) {
        drop_selector = drop.target;
      }
      replace_on_drop = typeof drop.replace === 'boolean' ? drop.replace : false;
      overflow_action = drop.overflow ? drop.overflow : false;
      draggables = document.querySelectorAll(drag_selector);
      droppables = _body.querySelectorAll(drop_selector);
      for (i = 0, len = draggables.length; i < len; i++) {
        draggable = draggables[i];
        draggable.draggable = true;
        disableNestedImageDrag(draggable);
        draggable.addEventListener('dragstart', function(e) {
          e.dataTransfer.effectAllowed = 'move';
          _current_draggable = e.srcElement;
          _current_drop_selector = drop_selector;
          draggable.classList.add('drag');
          return false;
        });
        draggable.addEventListener('dragend', function(e) {
          draggable.classList.remove('drag');
          _current_draggable = null;
          return false;
        });
      }
      results = [];
      for (j = 0, len1 = droppables.length; j < len1; j++) {
        droppable = droppables[j];
        droppable.addEventListener('dragover', function(e) {
          if (_current_drop_selector === drop_selector) {
            if (e.preventDefault) {
              e.preventDefault();
            }
            e.dataTransfer.dropEffect = 'move';
            droppable.classList.add('over');
            fireCallbacks('dragover', e);
          } else if (_current_draggable.parentNode === droppable) {
            if (e.preventDefault) {
              e.preventDefault();
            }
            _current_draggable.style.opacity = 0;
            if (e.target === droppable) {
              insertNextTo(_current_draggable, droppable.lastChild);
            } else {
              insertNextTo(_current_draggable, getSortable(e.target, droppable));
            }
            fireCallbacks('dragover', e);
          }
          return false;
        });
        droppable.addEventListener('dragenter', function(e) {
          if (_current_drop_selector === drop_selector) {
            droppable.classList.add('over');
            fireCallbacks('dragenter', e);
          }
          return false;
        });
        droppable.addEventListener('dragleave', function(e) {
          droppable.classList.remove('over');
          return false;
        });
        results.push(droppable.addEventListener('drop', function(e) {
          var clone, clone_img;
          if (e.stopPropagation) {
            e.stopPropagation();
          }
          if (_current_drop_selector === drop_selector) {
            droppable.classList.remove('over');
            clone = _current_draggable.cloneNode(true);
            makeRemovable(clone);
            if (replace_on_drop) {
              droppable.innerHTML = '';
              droppable.appendChild(clone);
            } else {
              makeSortable(clone);
              if (e.target === droppable) {
                droppable.appendChild(clone);
              } else {
                insertNextTo(clone, getSortable(e.target, droppable));
              }
            }
            if (clone_img = clone.querySelector('img')) {
              clone_img.onload = function() {
                if (droppable.scrollHeight > droppable.clientHeight) {
                  return onOverflow(droppable, clone, overflow_action);
                }
              };
            } else {
              if (droppable.scrollHeight > droppable.clientHeight) {
                onOverflow(droppable, clone, overflow_action);
              }
            }
            fireCallbacks('drop update', e);
          }
          return false;
        }));
      }
      return results;
    };
    disableNestedImageDrag = function(el) {
      var i, image, images_in_draggable, len, results;
      images_in_draggable = el.querySelectorAll('img');
      results = [];
      for (i = 0, len = images_in_draggable.length; i < len; i++) {
        image = images_in_draggable[i];
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
    makeSortable = function(el) {
      el.draggable = true;
      el.classList.add('sortable');
      el.addEventListener('dragstart', function(e) {
        e.dataTransfer.dropEffect = 'move';
        e.dataTransfer.effectAllowed = 'move';
        _current_draggable = e.srcElement;
        el.classList.add('drag');
        return false;
      });
      return el.addEventListener('dragend', function(e) {
        el.classList.remove('drag');
        _current_draggable.style.opacity = 1;
        _current_draggable = null;
        return false;
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
    onTrashClick = function(e) {
      var el;
      el = e.target.parentNode;
      el.remove();
      return fireCallbacks('remove update', e);
    };
    onOverflow = function(droppable, last_el, action) {
      var el, els, i, l, len, max_height, max_height_percentage, overflow, results;
      switch (action) {
        case 'shrinkAll':
          els = droppable.querySelectorAll('.removable');
          l = els.length;
          results = [];
          for (i = 0, len = els.length; i < len; i++) {
            el = els[i];
            results.push(el.style.maxHeight = (100 / l) + '%');
          }
          return results;
          break;
        case 'shrinkLast':
          last_el = droppable.lastElementChild;
          console.log(last_el);
          overflow = droppable.scrollHeight - droppable.clientHeight;
          max_height = last_el.clientHeight - overflow;
          max_height_percentage = (max_height / droppable.clientHeight) * 100;
          return last_el.style.height = max_height_percentage + '%';
        default:
          last_el.remove();
          droppable.classList.add('nodrop');
          droppable.offsetWidth = droppable.offsetWidth;
          droppable.classList.add('fade');
          droppable.offsetWidth = droppable.offsetWidth;
          droppable.classList.remove('nodrop');
          return setTimeout(function() {
            return droppable.classList.remove('fade');
          }, 1000);
      }
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
      if (page && typeof page === 'Integer') {
        return _pages[page].innerHTML;
      }
      return _body.innerHTML;
    };
    print = function() {};
    init(selector, options);
    return {
      print: print,
      on: setCallback,
      get: getHTML
    };
  };

  window.aPRINT = function(selector, options) {
    return new A(selector, options);
  };

}).call(this);
