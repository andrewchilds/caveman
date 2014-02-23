Caveman = require('../caveman.js')

beforeEach ->
  Caveman.options.openTag = '{{';
  Caveman.options.closeTag = '}}';
  Caveman.options.shrinkWrap = true;

describe 'Partials', ->

  it 'should be able to save a partial', ->
    expect(Caveman.partials.emailLink).toBe undefined
    template = '<a href="mailto:{{d.email}}" class="{{d.className}}">{{d.email}}</a>'
    Caveman.register('emailLink', template)
    expect(Caveman.partials.emailLink).not.toBe undefined

  it 'should be able to render a partial', ->
    data = {
      users: [
        { email: 'jimmy@gmail.com' }
        { email: 'ralph@gmail.com', className: 'active' }
        { email: 'joe@gmail.com' }
      ]
    }
    template = """
      {{- for d.users }}
        <div class="user">{{- render emailLink }}</div>
      {{- end }}
      """
    expected = '<div class="user">' +
      '<a href="mailto:jimmy@gmail.com" class="">jimmy@gmail.com</a>' +
      '</div>' +
      '<div class="user">' +
      '<a href="mailto:ralph@gmail.com" class="active">ralph@gmail.com</a>' +
      '</div>' +
      '<div class="user">' +
      '<a href="mailto:joe@gmail.com" class="">joe@gmail.com</a>' +
      '</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'should be able to render a partial with an optional scope', ->
    data = {
      users: [
        { email: 'jimmy@gmail.com' }
        { email: 'ralph@gmail.com', className: 'active' }
        { email: 'joe@gmail.com' }
      ]
    }
    template = """
      <div class="user">{{- render emailLink d.users[1] }}</div>
      """
    expected = '<div class="user">' +
      '<a href="mailto:ralph@gmail.com" class="active">ralph@gmail.com</a>' +
      '</div>'
    expect(Caveman(template, data)).toEqual(expected)
