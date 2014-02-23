Caveman = require('../caveman.js')

beforeEach ->
  Caveman.options.openTag = '{{';
  Caveman.options.closeTag = '}}';
  Caveman.options.shrinkWrap = true;

describe 'Custom Macros', ->

  it 'should be able to save a custom macro', ->
    expect(Caveman.macros.tableClass).toBe undefined
    Caveman.addMacro('tableClass', {
      find: /^tableClass$/
      replace: "str += (_i % 2 ? 'even' : 'odd');" +
        "if (_i === 0) { str += ' first'; }" +
        "if (_i === _len - 1) { str += ' last'; }";
    })
    expect(Caveman.macros.tableClass).not.toBe undefined

  it 'should be able to use a custom macro', ->
    data = {
      rows: [
        { text: 'a' }
        { text: 'b' }
        { text: 'c' }
      ]
    }
    template = """
      <table>
        {{- for d.rows }}
          <tr class="{{- tableClass }}">
            <td>{{d.text}}</td>
          </tr>
        {{- end }}
      </table>
      """
    expected = '<table>' +
        '<tr class="odd first"><td>a</td></tr>' +
        '<tr class="even"><td>b</td></tr>' +
        '<tr class="odd last"><td>c</td></tr>' +
      '</table>'
    expect(Caveman(template, data)).toEqual(expected)
