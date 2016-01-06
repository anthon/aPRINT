// Generated by CoffeeScript 1.10.0
(function() {
  var A;

  A = function(selector, options) {
    var _baseStyle, _body, _current_draggable, _frame, _pages, _settings, activateContent, addDragDroppable, createIframe, disableNestedImageDrag, getSortable, init, insertNextTo, insertStyle, makeRemovable, makeSortable, onTrashClick, print, setupListeners;
    _frame = null;
    _body = null;
    _pages = null;
    _current_draggable = null;
    _baseStyle = '* { -webkit-box-sizing: border-box; -moz-box-sizing: border-box; -ms-box-sizing: border-box; -o-box-sizing: border-box; box-sizing: border-box; margin: 0; padding: 0; outline: none; } html { font-size: 12pt; } body { background: #808080; } body .over { background: #94ff94; } body .removable { position: relative; } body .removable .remove { font-family: sans-serif; background: #fff; position: absolute; top: 6px; right: 6px; padding: 3px 7px; font-size: 1rem; font-weight: 100; color: #000; cursor: pointer; } body .removable .remove:hover { background: #c20000; color: #fff; } body .page { background: #fff; margin: 2mm auto; } body .page.A4 { width: 210mm; height: 297mm; padding: 15mm 20mm; }';
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
      _frame.style.borderWidth = 0;
      _body.parentNode.insertBefore(_frame, _body);
      _frame.contentDocument.body.appendChild(_body);
      insertStyle(_baseStyle);
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
      var i, j, len, len1, removable, removables, results, sortable, sortables;
      sortables = _body.querySelectorAll('.sortable');
      removables = _body.querySelectorAll('.removable');
      for (i = 0, len = sortables.length; i < len; i++) {
        sortable = sortables[i];
        disableNestedImageDrag(sortable);
        makeSortable(sortable);
      }
      results = [];
      for (j = 0, len1 = removables.length; j < len1; j++) {
        removable = removables[j];
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
      var drag_selector, draggable, draggables, drop_selector, droppable, droppables, i, j, len, len1, replace_on_drop, results;
      drag_selector = drag;
      if (typeof drop === 'string') {
        drop_selector = drop;
      } else if (drop.target) {
        drop_selector = drop.target;
      }
      replace_on_drop = typeof drop.replace === 'boolean' ? drop.replace : false;
      draggables = document.querySelectorAll(drag_selector);
      droppables = _body.querySelectorAll(drop_selector);
      for (i = 0, len = draggables.length; i < len; i++) {
        draggable = draggables[i];
        console.log('Adding draggable:', draggable);
        draggable.draggable = true;
        disableNestedImageDrag(draggable);
        draggable.addEventListener('dragstart', function(e) {
          console.log(e);
          e.dataTransfer.effectAllowed = 'move';
          _current_draggable = e.srcElement;
          e.dataTransfer.setData('drop_on', drop_selector);
          draggable.classList.add('drag');
          return false;
        });
        draggable.addEventListener('dragend', function(e) {
          console.log(e);
          draggable.classList.remove('drag');
          _current_draggable = null;
          return false;
        });
      }
      results = [];
      for (j = 0, len1 = droppables.length; j < len1; j++) {
        droppable = droppables[j];
        console.log('Adding droppable:', droppable);
        droppable.addEventListener('dragover', function(e) {
          console.log(e);
          if (e.dataTransfer.getData('drop_on') === drop_selector) {
            if (e.preventDefault) {
              e.preventDefault();
            }
            e.dataTransfer.dropEffect = 'move';
            this.classList.add('over');
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
          }
          return false;
        });
        droppable.addEventListener('dragenter', function(e) {
          console.log(e);
          if (e.dataTransfer.getData('drop_on') === drop_selector) {
            this.classList.add('over');
          }
          return false;
        });
        droppable.addEventListener('dragleave', function(e) {
          console.log(e);
          this.classList.remove('over');
          return false;
        });
        results.push(droppable.addEventListener('drop', function(e) {
          var clone;
          console.log(e);
          if (e.stopPropagation) {
            e.stopPropagation();
          }
          if (e.dataTransfer.getData('drop_on') === drop_selector) {
            this.classList.remove('over');
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
      console.log(el);
      return el;
    };
    onTrashClick = function(e) {
      var el;
      el = e.target.parentNode;
      return el.remove();
    };
    print = function() {};
    init(selector, options);
    return {
      print: print
    };
  };

  window.aPRINT = function(selector, options) {
    return new A(selector, options);
  };

}).call(this);
