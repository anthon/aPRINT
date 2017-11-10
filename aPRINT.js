// Generated by CoffeeScript 1.10.0
(function() {
  var A;

  A = function(body, options) {
    var _body, _callbacks, _current_drag_selector, _current_draggable, _current_rule, _current_sortable_target, _drag_image, _frame, _is_sorting, _mm2px, _paper_width, _rules, _sections, _settings, activateContent, activateKeys, addEventListener, addFeatures, addPage, addPageFeatures, applyRule, applyRules, assignImageNumbers, checkOverflow, consolidate, createIframe, createNode, disableNestedImageDrag, fireCallbacks, frameResize, getHTML, getID, getNode, getNodes, getSortable, highlightPotentials, init, insertNextTo, insertStyle, itemise, lowlightPotentials, makeClassable, makeRemovable, makeSortable, onAddPageClick, onDraggableDragEnd, onDraggableDragStart, onDroppableDragEnter, onDroppableDragLeave, onDroppableDragOver, onDroppableDrop, onKeyDown, onTrashClick, onWindowResize, parentItem, parentPage, parentSection, populateIframe, print, refreshPages, refuseDrop, removeFeatures, removeItem, renderTemplate, scrollTo, scrollToEl, setCallback, updateDOM, walkDOM, walkTemplate;
    _mm2px = 3.78;
    _paper_width = 210;
    _frame = null;
    _body = null;
    _sections = null;
    _callbacks = {};
    _current_draggable = null;
    _current_drag_selector = null;
    _current_sortable_target = null;
    _drag_image = null;
    _is_sorting = false;
    _rules = {};
    _current_rule = null;
    _settings = {
      styles: ['../aPRINT.css'],
      id: 'aPRINT',
      format: 'A4',
      transparent: false,
      editable: true,
      mirror: true,
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
      _frame = document.createElement('iframe');
      _frame.style.borderWidth = 0;
      _drag_image = document.querySelector('#aPRINT-image-drag');
      if (!_drag_image) {
        _drag_image = document.createElement('div');
        _drag_image.id = 'aPRINT-image-drag';
        _drag_image.style.width = '124px';
        _drag_image.style.height = '124px';
        _drag_image.style.backgroundPosition = 'center center';
        _drag_image.style.backgroundSize = 'contain';
        document.body.appendChild(_drag_image);
      }
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
      var j, len, ref, stylesheet;
      _frame.contentDocument.body.classList.add(_settings.format);
      _frame.contentDocument.body.appendChild(_body);
      if (typeof _settings.styles === 'string') {
        _settings.styles = [_settings.styles];
      }
      ref = _settings.styles;
      for (j = 0, len = ref.length; j < len; j++) {
        stylesheet = ref[j];
        insertStyle(stylesheet);
      }
      if (_settings.template) {
        renderTemplate();
      }
      if (_settings.editable) {
        applyRules();
        activateContent();
      }
      activateKeys();
      frameResize();
      refreshPages();
      return fireCallbacks('loaded');
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
      var item, items, j, len, len1, m, page, pages, results;
      pages = _body.querySelectorAll('.page');
      for (j = 0, len = pages.length; j < len; j++) {
        page = pages[j];
        disableNestedImageDrag(page);
        addPageFeatures(page);
      }
      items = _body.querySelectorAll('[data-item]');
      results = [];
      for (m = 0, len1 = items.length; m < len1; m++) {
        item = items[m];
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
      var el, els, index, j, len, r, r_bottom, r_top, wb;
      els = _body.querySelectorAll(selector);
      wb = _frame.contentWindow.innerHeight;
      for (index = j = 0, len = els.length; j < len; index = ++j) {
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
      var act_width, factor, margin, max_width;
      margin = 24;
      max_width = (_paper_width + margin) * _mm2px;
      act_width = _frame.offsetWidth;
      factor = act_width / max_width;
      _frame.contentDocument.body.style.transform = 'scale(' + factor + ')';
      return _frame.contentDocument.body.style.marginLeft = ((act_width - max_width) / 2 + margin) + 'px';
    };
    renderTemplate = function() {
      var element, from_scratch, key, placeholder, placeholders, ref;
      placeholder = _body.querySelector('section');
      if (!placeholder) {
        from_scratch = true;
        placeholder = document.createElement('section');
      } else {
        from_scratch = false;
      }
      placeholders = [placeholder];
      ref = _settings.template;
      for (key in ref) {
        element = ref[key];
        walkTemplate(placeholders, key, element, function(parent, identifier, element) {
          var _node, child, child_node, cls, id, j, len, len1, m, node, nodes, ref1, ref2;
          nodes = _body.querySelectorAll('[data-template-identifier=' + identifier + ']');
          if (nodes.length === 0) {
            node = createNode(identifier);
            parent.appendChild(node);
            nodes = [node];
          }
          for (j = 0, len = nodes.length; j < len; j++) {
            node = nodes[j];
            if (element.children) {
              _node = node.cloneNode(false);
              ref1 = element.children;
              for (id in ref1) {
                child = ref1[id];
                child_node = getNode(id, node);
                if (!child_node) {
                  child_node = createNode(id);
                }
                _node.appendChild(child_node);
              }
              node.innerHTML = _node.innerHTML;
            }
            if (element.classes) {
              node.classList.remove();
              ref2 = element.classes;
              for (m = 0, len1 = ref2.length; m < len1; m++) {
                cls = ref2[m];
                node.classList.add(cls);
              }
            }
          }
          return nodes;
        });
      }
      if (from_scratch) {
        return _body.appendChild(placeholder);
      }
    };
    getNode = function(identifier, parent) {
      parent = parent || _body;
      return parent.querySelector('[data-template-identifier=' + identifier + ']');
    };
    getNodes = function(identifier, parent) {
      parent = parent || _body;
      return parent.querySelectorAll('[data-template-identifier=' + identifier + ']');
    };
    createNode = function(identifier) {
      var node;
      node = document.createElement('div');
      node.dataset.templateIdentifier = identifier;
      return node;
    };
    walkTemplate = function(parent_nodes, identifier, element, func) {
      var child, children, j, key, len, nodes, parent_node, results;
      results = [];
      for (j = 0, len = parent_nodes.length; j < len; j++) {
        parent_node = parent_nodes[j];
        nodes = func(parent_node, identifier, element);
        children = element.children ? element.children : {};
        results.push((function() {
          var results1;
          results1 = [];
          for (key in children) {
            child = children[key];
            results1.push(walkTemplate(nodes, key, child, func));
          }
          return results1;
        })());
      }
      return results;
    };
    updateDOM = function() {
      return walkDOM(_body, function(node) {});
    };
    walkDOM = function(node, func) {
      var results;
      func(node);
      node = node.firstChild;
      results = [];
      while (node) {
        walkTemplate(node, func);
        results.push(node = node.nextSibling);
      }
      return results;
    };
    refreshPages = function() {
      var j, len, page, pages, results, section, seq;
      if (_settings.mirror) {
        _sections = _body.querySelectorAll('section');
        results = [];
        for (j = 0, len = _sections.length; j < len; j++) {
          section = _sections[j];
          pages = section.querySelectorAll('.page');
          seq = 'odd';
          results.push((function() {
            var len1, m, results1;
            results1 = [];
            for (m = 0, len1 = pages.length; m < len1; m++) {
              page = pages[m];
              page.classList.remove('even', 'odd');
              page.classList.add(seq);
              results1.push(seq = seq === 'odd' ? 'even' : 'odd');
            }
            return results1;
          })());
        }
        return results;
      }
    };
    addPageFeatures = function(page) {
      var adder, trasher;
      if (page.dataset.repeatable) {
        adder = page.querySelector('.add_page');
        if (!adder) {
          adder = document.createElement('div');
          adder.classList.add('add_page');
          adder.innerHTML = '+';
          page.appendChild(adder);
        }
        adder.addEventListener('click', onAddPageClick);
      }
      if (page.dataset.removable) {
        trasher = page.querySelector('.remove');
        if (!trasher) {
          trasher = document.createElement('div');
          trasher.innerHTML = '&times;';
          trasher.classList.add('remove');
          page.appendChild(trasher);
        }
        return trasher.addEventListener('click', onTrashClick);
      }
    };
    itemise = function(el, sibling) {
      delete el.dataset.selector;
      return el.dataset.item = sibling ? sibling.dataset.id : getID();
    };
    applyRules = function() {
      var ref, results, rule, target;
      ref = _settings.rules;
      results = [];
      for (target in ref) {
        rule = ref[target];
        results.push(applyRule(target, rule));
      }
      return results;
    };
    applyRule = function(target, rule) {
      var drag_selector, drag_selectors, draggable, draggables, drop_classes, droppable, j, len, len1, len2, m, n, overflow_action, removable, repeatable, replaceable, results, sortable, target_selector, targets;
      target_selector = target;
      targets = _body.querySelectorAll(target_selector);
      removable = typeof rule.removable === 'boolean' ? rule.removable : false;
      repeatable = typeof rule.repeatable === 'boolean' ? rule.repeatable : false;
      for (j = 0, len = targets.length; j < len; j++) {
        target = targets[j];
        if (removable) {
          target.dataset.removable = removable;
        }
        if (repeatable) {
          target.dataset.repeatable = repeatable;
        }
      }
      if (rule.accept) {
        drag_selectors = typeof rule.accept === 'string' ? [rule.accept] : rule.accept;
        replaceable = typeof rule.replaceable === 'boolean' ? rule.replaceable : false;
        sortable = typeof rule.sortable === 'boolean' ? rule.sortable : false;
        overflow_action = rule.overflow ? rule.overflow : false;
        drop_classes = rule.classes ? rule.classes : false;
        for (m = 0, len1 = targets.length; m < len1; m++) {
          droppable = targets[m];
          if (drop_classes) {
            droppable.dataset.classList = drop_classes;
          }
          if (sortable) {
            droppable.dataset.sortable = sortable;
          }
          if (replaceable) {
            droppable.dataset.replaceable = replaceable;
          }
          if (overflow_action) {
            droppable.dataset.overflow = overflow_action;
          }
          droppable.dataset.dropSelector = target_selector;
          droppable.dataset.accept = drag_selectors;
          addEventListener(droppable, 'dragover', onDroppableDragOver);
          addEventListener(droppable, 'dragenter', onDroppableDragEnter);
          addEventListener(droppable, 'dragleave', onDroppableDragLeave);
          addEventListener(droppable, 'drop', onDroppableDrop);
        }
        results = [];
        for (n = 0, len2 = drag_selectors.length; n < len2; n++) {
          drag_selector = drag_selectors[n];
          draggables = document.querySelectorAll(drag_selector);
          results.push((function() {
            var len3, o, results1;
            results1 = [];
            for (o = 0, len3 = draggables.length; o < len3; o++) {
              draggable = draggables[o];
              draggable.draggable = true;
              draggable.dataset.selector = drag_selector;
              disableNestedImageDrag(draggable);
              addEventListener(draggable, 'dragstart', onDraggableDragStart);
              results1.push(addEventListener(draggable, 'dragend', onDraggableDragEnd));
            }
            return results1;
          })());
        }
        return results;
      }
    };
    disableNestedImageDrag = function(el) {
      var image, images_in_draggable, j, len, results;
      images_in_draggable = el.querySelectorAll('img');
      results = [];
      for (j = 0, len = images_in_draggable.length; j < len; j++) {
        image = images_in_draggable[j];
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
    makeRemovable = function(el, droppable) {
      var trasher;
      if (!droppable) {
        droppable = el.parentNode;
      }
      if (droppable.dataset.removable) {
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
    makeClassable = function(el, droppable) {
      var class_list, cls, container, expander, item, items, j, len, len1, list, m, results;
      if (!droppable) {
        droppable = el.parentNode;
      }
      if (droppable.dataset.classList) {
        items = el.querySelectorAll('.classes .item');
        class_list = droppable.dataset.classList.split(',');
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
          for (j = 0, len = class_list.length; j < len; j++) {
            cls = class_list[j];
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
        for (m = 0, len1 = items.length; m < len1; m++) {
          item = items[m];
          results.push(item.addEventListener('click', function(e) {
            var len2, len3, n, o, results1, set, set_el;
            set = _body.querySelectorAll('[data-item="' + el.dataset.item + '"]');
            results1 = [];
            for (n = 0, len2 = set.length; n < len2; n++) {
              set_el = set[n];
              for (o = 0, len3 = class_list.length; o < len3; o++) {
                cls = class_list[o];
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
    makeSortable = function(el, droppable) {
      if (!droppable) {
        droppable = el.parentNode;
      }
      if (droppable.dataset.sortable) {
        disableNestedImageDrag(el);
        el.draggable = true;
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
      var j, len, results, to_remove, to_removes;
      to_removes = el.querySelectorAll('.add_page, .classes, .remove');
      results = [];
      for (j = 0, len = to_removes.length; j < len; j++) {
        to_remove = to_removes[j];
        results.push(to_remove.remove());
      }
      return results;
    };
    assignImageNumbers = function(section) {
      var i, img, imgs, item, j, len, results;
      console.log(section);
      imgs = section.querySelectorAll('img');
      results = [];
      for (i = j = 0, len = imgs.length; j < len; i = ++j) {
        img = imgs[i];
        item = parentItem(img);
        results.push(item.dataset.imageNumber = i + 1);
      }
      return results;
    };
    highlightPotentials = function() {
      var droppable, droppables, j, len, results;
      droppables = _body.querySelectorAll('[data-drop-selector]');
      results = [];
      for (j = 0, len = droppables.length; j < len; j++) {
        droppable = droppables[j];
        if (droppable.dataset.accept.indexOf(_current_drag_selector) !== -1) {
          results.push(droppable.classList.add('potential'));
        } else {
          results.push(void 0);
        }
      }
      return results;
    };
    lowlightPotentials = function() {
      var j, len, potential, potentials, results;
      potentials = _body.querySelectorAll('.potential');
      results = [];
      for (j = 0, len = potentials.length; j < len; j++) {
        potential = potentials[j];
        results.push(potential.classList.remove('potential'));
      }
      return results;
    };
    onDraggableDragStart = function(e) {
      var dt, img, that;
      that = this;
      dt = e.dataTransfer;
      _current_draggable = e.target;
      _current_drag_selector = that.dataset.selector;
      dt.effectAllowed = 'move';
      dt.setData('source', 'external');
      if (dt.setDragImage) {
        img = _current_draggable.querySelector('img');
        if (img) {
          _drag_image.style.backgroundImage = 'url(' + img.src + ')';
          dt.setDragImage(_drag_image, 62, 62);
        }
      }
      that.classList.add('drag');
      highlightPotentials();
      return false;
    };
    onDraggableDragEnd = function(e) {
      var that;
      that = this;
      that.classList.remove('drag');
      _current_draggable = null;
      _current_drag_selector = null;
      lowlightPotentials();
      return false;
    };
    onDroppableDragOver = function(e) {
      var that;
      that = this;
      if (that.dataset.accept.indexOf(_current_drag_selector) !== -1) {
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
      if (that.dataset.accept.indexOf(_current_drag_selector) !== -1) {
        that.classList.add('over');
        fireCallbacks('dragenter', e);
      }
      return false;
    };
    onDroppableDragLeave = function(e) {
      var _current_drop_selector, that;
      that = this;
      _current_drop_selector = null;
      that.classList.remove('over');
      return false;
    };
    onDroppableDrop = function(e) {
      var clone, clone_img, that;
      that = this;
      if (e.stopPropagation) {
        e.stopPropagation();
      }
      if (that.dataset.accept.indexOf(_current_drag_selector) !== -1) {
        lowlightPotentials();
        that.classList.remove('over');
        clone = _current_draggable.cloneNode(true);
        clone.removeAttribute('draggable');
        clone.classList.remove('drag');
        itemise(clone);
        if (that.dataset.replaceable) {
          that.innerHTML = '';
          that.appendChild(clone);
        } else {
          makeSortable(clone, that);
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
          assignImageNumbers(parentSection(that));
        } else {
          checkOverflow(that, clone, true);
        }
        makeRemovable(clone, that);
        makeClassable(clone, that);
      } else if (_is_sorting) {
        checkOverflow(that);
        assignImageNumbers(parentSection(that));
      }
      fireCallbacks('drop');
      return false;
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
      var item, items, j, len, new_page, section;
      section = page.parentNode;
      if (page) {
        new_page = page.cloneNode(true);
      } else {
        new_page = _body.querySelector('.page').cloneNode(true);
      }
      items = new_page.querySelectorAll('[data-item],.add_page');
      for (j = 0, len = items.length; j < len; j++) {
        item = items[j];
        item.remove();
      }
      new_page.dataset.repeatable = true;
      new_page.dataset.removable = true;
      section.insertBefore(new_page, page.nextSibling);
      addPageFeatures(new_page);
      refreshPages();
      frameResize();
      applyRules();
      return new_page;
    };
    onTrashClick = function(e) {
      var el, item, items, j, len, sure, to_remove;
      el = e.target.parentNode;
      to_remove = el.dataset.item ? 'item' : 'page';
      sure = confirm('Are you sure you want to remove the ' + to_remove + '?');
      if (sure) {
        if (to_remove === 'page') {
          items = el.querySelectorAll('[data-item]');
          for (j = 0, len = items.length; j < len; j++) {
            item = items[j];
            removeItem(item);
          }
          el.remove();
          refreshPages();
        } else {
          removeItem(el);
        }
        fireCallbacks('remove', e);
        return fireCallbacks('update', e);
      }
    };
    removeItem = function(el) {
      var droppable, j, len, results, set, set_el;
      set = _body.querySelectorAll('[data-item="' + el.dataset.item + '"]');
      results = [];
      for (j = 0, len = set.length; j < len; j++) {
        set_el = set[j];
        droppable = set_el.parentNode;
        set_el.remove();
        checkOverflow(droppable, null, true);
        results.push(assignImageNumbers(parentSection(droppable)));
      }
      return results;
    };
    consolidate = function(el) {
      var els, j, len, results, set_el;
      els = _body.querySelectorAll('[data-item="' + el.dataset.item + '"]');
      if (els.length > 1) {
        results = [];
        for (j = 0, len = els.length; j < len; j++) {
          set_el = els[j];
          if (!set_el.dataset.slave) {
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
      var action, cl, continuer, dop, droppable_height, droppable_index, droppables_on_page, drp, drps, el, els, fc, fcHTML, j, l, last_el, lc, len, len1, len2, m, max_height, max_height_factor, max_height_percentage, n, next_page, overflow, page, results;
      if (_is_sorting || !element) {
        els = droppable.querySelectorAll('[data-item]');
        for (j = 0, len = els.length; j < len; j++) {
          el = els[j];
          el.style.height = 'auto';
          if (!el.dataset.slave) {
            consolidate(el);
          }
        }
      }
      droppable_height = droppable.clientHeight;
      if (droppable.scrollHeight > droppable_height) {
        action = droppable.dataset.overflow;
        switch (action) {
          case 'continue':
            last_el = droppable.lastElementChild;
            if (last_el) {
              removeFeatures(last_el);
              if (!last_el.dataset.slave) {
                last_el.dataset.content = last_el.innerHTML;
              }
              continuer = last_el.cloneNode();
              continuer.dataset.slave = true;
              l = 20000;
              while (l-- && droppable.scrollHeight > droppable_height) {
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
              l = 20000;
              while (l-- && droppable.scrollHeight > droppable_height) {
                fcHTML = fc.innerHTML.split(' ');
                cl.innerHTML = fcHTML.pop() + ' ' + cl.innerHTML;
                fc.innerHTML = fcHTML.join(' ');
              }
              continuer.insertBefore(cl, continuer.firstChild);
              page = parentPage(droppable);
              drps = page.querySelectorAll('[data-drop-selector="' + droppable.dataset.dropSelector + '"]');
              droppable_index = Array.prototype.indexOf.call(drps, droppable);
              drp = drps[droppable_index + 1];
              if (!drp || drp === droppable) {
                next_page = page.nextElementSibling;
                if (!next_page || next_page.nodeType !== 1) {
                  next_page = addPage(page);
                }
                drp = next_page.querySelector('[data-drop-selector="' + droppable.dataset.dropSelector + '"]');
              }
              drp.insertBefore(continuer, drp.firstChild);
              if (!last_el.dataset.slave) {
                addFeatures(last_el);
              }
              checkOverflow(drp);
            }
            fireCallbacks('update');
            break;
          case 'shrinkAll':
            els = droppable.querySelectorAll('.removable');
            l = els.length;
            for (m = 0, len1 = els.length; m < len1; m++) {
              el = els[m];
              el.style.maxHeight = (100 / l) + '%';
            }
            fireCallbacks('update');
            break;
          case 'shrinkLast':
            last_el = droppable.lastElementChild;
            if (last_el) {
              overflow = droppable.scrollHeight - droppable_height;
              max_height = last_el.clientHeight - overflow;
              if (max_height > 0) {
                max_height_factor = max_height / droppable_height;
                max_height_percentage = max_height_factor * 100;
                last_el.style.height = (max_height / _mm2px) + 'mm';
                fireCallbacks('update');
              } else {
                if (!_is_sorting && element) {
                  element.remove();
                }
                refuseDrop(droppable);
              }
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
        for (n = 0, len2 = droppables_on_page.length; n < len2; n++) {
          dop = droppables_on_page[n];
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
    parentSection = function(el) {
      while (el.nodeName !== 'SECTION') {
        el = el.parentNode;
      }
      return el;
    };
    parentItem = function(el) {
      while (!el.dataset.item) {
        el = el.parentNode;
      }
      return el;
    };
    getID = function() {
      return Math.random().toString(36).substring(8);
    };
    fireCallbacks = function(key, e) {
      var callback, j, k, keys, len, results;
      keys = key.split(' ');
      results = [];
      for (j = 0, len = keys.length; j < len; j++) {
        k = keys[j];
        if (_callbacks[k]) {
          results.push((function() {
            var len1, m, ref, results1;
            ref = _callbacks[k];
            results1 = [];
            for (m = 0, len1 = ref.length; m < len1; m++) {
              callback = ref[m];
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
      lowlightPotentials();
      if (section) {
        clone = _body.querySelector('section[data-id="' + section + '"]').cloneNode(true);
      } else {
        clone = _body.querySelector('section').cloneNode(true);
      }
      removeFeatures(clone);
      return clone.innerHTML.trim();
    };
    print = function() {
      _frame.contentWindow.print();
      return false;
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
