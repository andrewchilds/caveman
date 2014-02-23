Caveman = require('../caveman.js')

beforeEach ->
  Caveman.options.openTag = '{{';
  Caveman.options.closeTag = '}}';
  Caveman.options.shrinkWrap = true;

describe 'Custom Tag Options', ->

  beforeEach ->
    Caveman.options.openTag = '<%';
    Caveman.options.closeTag = '%>';

  it 'should handle custom tags', ->
    data = {
      users: [
        { name: 'Mario' }
        { name: 'Luigi' }
      ]
    }
    template = """
      <users>
        <%- for d.users as user %>
          <user><% user.name %></user>
        <%- end %>
      </users>
      """
    expected = '<users><user>Mario</user><user>Luigi</user></users>'
    expect(Caveman(template, data)).toEqual(expected)
