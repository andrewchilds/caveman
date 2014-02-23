/**
 * Caveman
 * https://github.com/andrewchilds/caveman
 */
;(function () {

  var partials = {};
  var macros = {};
  var blockState = [];
  var prefixes = {};

  var options = {
    openTag: '{{',
    closeTag: '}}',
    shrinkWrap: false // remove whitespace between variables
  };

  var addMacro = function (name, macro) {
    macros[name] = macro;
  };

  var each = function (obj, fn) {
    if (obj && obj.forEach) {
      return obj.forEach(fn);
    } else {
      for (var prop in obj) {
        if (obj.hasOwnProperty(prop)) {
          fn(obj[prop], prop);
        }
      }
    }
  };

  var escapeText = function (str) {
    return str.replace(/'/g, "\\'").replace(/^\n+|\n+$/g, '').replace(/\n/g, "'+'");
  };

  var escapeHTML = function (str) {
    return (str + '').replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/\'/g, '&#39;')
      .replace(/\"/g, '&quot;');
  };

  var shrinkWrapTemplate = function (str) {
    return str.replace(/^\s+/gm, '');
  };

  var resetBlockState = function () {
    blockState = [];
  };

  var pushBlockState = function (state) {
    blockState.push(state);
  };

  var popBlockState = function () {
    return blockState.pop();
  };

  var getBlockState = function () {
    return blockState;
  };

  var resetPrefix = function () {
    prefixes = {};
  };

  var addPrefix = function (name, prefix) {
    prefixes[name] = prefix;
  };

  var getPrefix = function () {
    var str = '';
    each(prefixes, function (prefix) {
      str += prefix;
    });

    return str;
  };

  var expandShortcuts = function (str) {
    var match = false;
    each(macros, function (macro, macroName) {
      var shortcut = macro.shortcut;
      if (!match && shortcut && shortcut.find.test(str)) {
        match = true;
        if (typeof shortcut.replace === 'string') {
          str = shortcut.replace;
        } else if (typeof shortcut.replace === 'function') {
          str = shortcut.replace(str);
        }
      }
    });

    return str;
  };

  var isScript = function (str) {
    return str && str.charAt(0) === '-';
  };

  var translateScript = function (str) {
    str = str.substr(1).trim(); // remove dash character

    var match = false;
    each(macros, function (macro, macroName) {
      if (!match && macro.find.test(str)) {
        match = true;
        if (typeof macro.replace === 'string') {
          str = macro.replace;
        } else if (typeof macro.replace === 'function') {
          str = macro.replace(str);
        }
        if (macro.blockEnd) {
          if (typeof macro.blockEnd === 'string') {
            pushBlockState(macro.blockEnd);
          } else if (typeof macro.blockEnd === 'function') {
            pushBlockState(macro.blockEnd());
          }
        }
        if (macro.prefix) {
          addPrefix(macroName, macro.prefix);
        }
      }
    });

    if (!match) {
      // script isn't using any macros
      return str + ';';
    }

    return str;
  };

  var compile = function (template) {
    if (typeof template !== 'string') {
      return '';
    }

    if (options.shrinkWrap) {
      template = shrinkWrapTemplate(template);
    }

    var output = "var _CfS = Caveman.forceStr; var str = '';";
    var parts = template.split(options.openTag);

    resetBlockState();
    resetPrefix();

    for (var i = 0; i < parts.length; i++) {
      var part = parts[i];
      if (part.indexOf(options.closeTag) !== -1) {
        part = part.split(options.closeTag);
      } else {
        part = ['', part];
      }
      var code = part[0];
      var text = part[1];

      if (code) {
        code = expandShortcuts(code);
        if (isScript(code)) {
          output += translateScript(code);
        } else {
          output += "str += _CfS(" + code + ");"
        }
      }
      if (text) {
        text = escapeText(text);
        output += ("str += '" + text + "';")
      }
    }

    return getPrefix() + output + 'return str;';
  };

  var forceStr = function (str) {
    return (typeof str === 'undefined' || str === null) ? '' : str;
  };

  // Readymade macros

  addMacro('if', {
    find: /^if /,
    replace: function (str) {
      return str.replace(/^if (.*)/, 'if ($1) {');
    },
    blockEnd: '}',
    shortcut: {
      find: /^\?\s?/,
      replace: function (str) {
        return str.replace(/^\?\s?(.*)/, '- if $1');
      }
    }
  });

  addMacro('unless', {
    find: /^unless /,
    replace: function (str) {
      return str.replace(/^unless (.*)/, 'if (!$1) {');
    },
    blockEnd: '}',
    shortcut: {
      find: /^\^\s?/,
      replace: function (str) {
        return str.replace(/^\^\s?(.*)/, '- unless $1');
      }
    }
  });

  addMacro('elseif', {
    find: /^else if /,
    replace: function (str) {
      return str.replace(/^else if (.*)/, '} else if ($1) {');
    }
  });

  addMacro('else', {
    find: /^else$/,
    replace: '} else {'
  });

  addMacro('end', {
    find: /^end$/,
    replace: function () {
      return popBlockState();
    },
    shortcut: {
      find: /^\/$/,
      replace: '- end '
    }
  });

  addMacro('for', {
    find: /^for /,
    prefix: 'var _ds = new Array(5), _i, _len;',
    replace: function (str) {
      var id = getBlockState().length;
      var js = '_ds.push(d); var _d' + id +
        ' = $1; for (var _i' + id + ' = 0, _len' + id + ' = ($1 || []).length; _i' +
        id + ' < _len' + id + '; _i' + id + '++) { _i = _i' + id +
        '; _len = _len' + id + ';';
      return str.replace(/^for (.*) as (.*)/, js + 'var $2 = _d' + id + '[_i' + id + '];')
        .replace(/^for (.*)/, js + 'd = _d' + id + '[_i' + id + '];');
    },
    blockEnd: function () {
      var id = getBlockState().length - 1;
      var resetIndex = '';
      if (id >= 0) {
        resetIndex = '_i = _i' + id + '; _len = _len' + id + ';';
      }
      return '} d = _ds.pop();' + resetIndex;
    }
  });

  addMacro('each', {
    find: /^each /,
    prefix: 'var _Ce = Caveman.each;',
    replace: function (str) {
      return str.replace(/^each (.*) as (.*)/, '_Ce($1, function ($2, _key) {')
        .replace(/^each (.*)/, '_Ce($1, function (d, _key) {');
    },
    blockEnd: '});'
  });

  addMacro('with', {
    find: /^with /,
    prefix: 'var _Cw = Caveman.each;',
    replace: function (str) {
      return str.replace(/^with (.*) as (.*)/, '_Cw([$1], function ($2, _key) {')
        .replace(/^with (.*)/, '_Cw([$1], function (d, _key) {');
    },
    blockEnd: '});'
  });

  addMacro('render', {
    find: /^render /,
    prefix: 'var _Cr = Caveman.render;',
    replace: function (str) {
      return str.replace(/^render (.*) (.*)/, 'str += _Cr(\'$1\', $2);')
        .replace(/^render (.*)/, 'str += _Cr(\'$1\', d);');
    }
  });

  addMacro('print', {
    find: /^print /,
    replace: function (str) {
      return str.replace(/^print (.*)/, 'str += ($1);');
    }
  });

  addMacro('log', {
    find: /^log /,
    replace: function (str) {
      return str.replace(/^log (.*)/, 'console.log($1);');
    }
  });

  addMacro('escape', {
    find: /^escape /,
    prefix: 'var _CeH = Caveman.escapeHTML;',
    replace: function (str) {
      return str.replace(/^escape (.*)/, 'str += _CeH($1);');
    }
  });

  addMacro('first', {
    find: /^first$/,
    replace: 'if (_i === 0) {',
    blockEnd: '}'
  });

  addMacro('last', {
    find: /^last$/,
    replace: 'if (_i === _len - 1) {',
    blockEnd: '}'
  });

  // Init

  var register = function (partialName, template) {
    if (typeof template === 'string') {
      template = Caveman(template);
    }
    return partials[partialName] = template;
  };

  var render = function (partialName, data) {
    if (partials[partialName]) {
      return partials[partialName](Caveman, data);
    } else {
      throw Error('Partial "' + partialName + '" not found.');
    }
  };

  var Caveman = function (template, data) {
    var compiled = compile(template, options);
    var fn = new Function('Caveman', 'd', compiled);
    var renderFn = function (Caveman, data) {
      return fn(Caveman, data);
    };
    renderFn.compiled = compiled;

    return data ? renderFn(Caveman, data) : renderFn;
  };

  Caveman.options = options;
  Caveman.each = each;
  Caveman.escapeHTML = escapeHTML;
  Caveman.compile = compile;
  Caveman.forceStr = forceStr;

  Caveman.partials = partials;
  Caveman.register = register;
  Caveman.render = render;

  Caveman.macros = macros;
  Caveman.addMacro = addMacro;
  Caveman.popBlockState = popBlockState;
  Caveman.pushBlockState = pushBlockState;

  // Expose

  if (typeof define === 'function' && define.amd) {
    define(function() { return Caveman; });
  } else if (typeof module === 'object' && typeof exports === 'object') {
    module.exports = Caveman;
  } else if (typeof window !== 'undefined') {
    window.Caveman = Caveman;
  }

}());
