Caveman = require('../caveman.js')

beforeEach ->
  Caveman.options.openTag = '{{';
  Caveman.options.closeTag = '}}';
  Caveman.options.shrinkWrap = true;

describe 'Interpolation', ->

  it 'without interpolation', ->
    data = {}
    template = 'foo bar foo'
    expected = 'foo bar foo'
    expect(Caveman(template, data)).toEqual(expected)

  it 'only interpolation', ->
    data = { a: '123', b: 234 }
    template = '{{d.a}}{{d.b}}'
    expected = '123234'
    expect(Caveman(template, data)).toEqual(expected)

  it 'strings', ->
    data = { a: '123', b: 'true', empty: '' }
    template = '| {{d.a}} | {{d.b}} | {{d.c}} |'
    expected = '| 123 | true |  |'
    expect(Caveman(template, data)).toEqual(expected)

  it 'numbers', ->
    data = { a: 123, b: 0.0, c: 1.01, d: 1 }
    template = '| {{d.a}} | {{d.b}} | {{d.c}} | {{d.d}} |'
    expected = '| 123 | 0 | 1.01 | 1 |'
    expect(Caveman(template, data)).toEqual(expected)

  it 'boolean', ->
    data = { a: true, b: false }
    template = '| {{d.a}} | {{d.b}} |'
    expected = '| true | false |'
    expect(Caveman(template, data)).toEqual(expected)

  it 'null and undefined', ->
    data = { a: null, b: undefined }
    template = '| {{d.a}} | {{d.b}} | {{d.c}} |'
    expected = '|  |  |  |'
    expect(Caveman(template, data)).toEqual(expected)

  it 'arrays', ->
    data = { a: [1, 2, 3], b: [] }
    template = '| {{d.a}} | {{d.b}} |'
    expected = '| 1,2,3 |  |'
    expect(Caveman(template, data)).toEqual(expected)

  it 'objects', ->
    data = { a: 123, b: 234 }
    template = '| {{d}} |'
    expected = '| [object Object] |'
    expect(Caveman(template, data)).toEqual(expected)

  it 'dot notation', ->
    data = {
      foo: {
        bar: 123
      }
    }
    template = '{{d.foo.bar}}'
    expected = '123'
    expect(Caveman(template, data)).toEqual(expected)

  it 'dot and bracket notation', ->
    data = {
      colors: [
        { name: 'red' }
        { name: 'blue' }
        { name: 'orange' }
        { name: 'white' }
      ]
    }
    template = 'My favorite color is {{d.colors[1].name}}.'
    expected = 'My favorite color is blue.'
    expect(Caveman(template, data)).toEqual(expected)

  it 'error handling', ->
    data = { a: 1, b: 2, c: 3 }
    template = '| {{{d.a{{d.b}} | {{}} | }}{{ | \\{\\{hello\\}\\} |'
    expected = '| {d.a2 |  |  | {{hello}} |'
    expect(Caveman(template, data)).toEqual(expected)
