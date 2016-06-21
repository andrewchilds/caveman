Caveman = require('../caveman.js')

beforeEach ->
  Caveman.options.openTag = '{{'
  Caveman.options.closeTag = '}}'
  Caveman.options.shrinkWrap = true
  Caveman.options.escapeByDefault = false

describe 'Macros', ->
  template = '<ul>{{- for d.uls as ul }}<li>{{ul.li}}</li>{{/}}</ul>'
  Caveman.register('unorderedList', template)
  template = '{{- for d.divs as div }}<div>{{- render unorderedList div }}</div>{{/}}'
  Caveman.register('listOfDivs', template)

  it 'if with truthy comparison', ->
    data = {
      tests: {
        boolTrue: true
        boolFalse: false
        zero: 0
        one: 1
        emptyString: ''
        emptyObject: {}
        emptyArray: []
      }
    }
    template = """
      {{- each d.tests }}
        {{- if d }}
          <truthy>{{_key}}</truthy>
        {{- end }}
      {{- end }}
      """
    expected = '<truthy>boolTrue</truthy>' +
      '<truthy>one</truthy>' +
      '<truthy>emptyObject</truthy>' +
      '<truthy>emptyArray</truthy>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'if with strict comparison', ->
    data = {
      emptyString: ''
      emptyArray: []
      arrayWithOne: [1]
    }
    template = """
      {{- if d.emptyString === '' }}
        <true>d.emptyString === ''</true>
      {{- end }}
      {{- if d.emptyArray.length === 0 }}
        <true>d.emptyArray.length === 0</true>
      {{- end }}
      {{- if d.arrayWithOne.length > 0 }}
        <true>d.arrayWithOne.length > 0</true>
      {{- end }}
      """
    expected = "<true>d.emptyString === ''</true>" +
      '<true>d.emptyArray.length === 0</true>' +
      '<true>d.arrayWithOne.length > 0</true>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'unless with falsey comparison', ->
    data = {
      tests: {
        boolTrue: true
        boolFalse: false
        zero: 0
        one: 1
        emptyString: ''
        emptyObject: {}
        emptyArray: []
      }
    }
    template = """
      {{- each d.tests }}
        {{- unless d }}
          <falsey>{{_key}}</falsey>
        {{- end }}
      {{- end }}
      """
    expected = '<falsey>boolFalse</falsey>' +
      '<falsey>zero</falsey>' +
      '<falsey>emptyString</falsey>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'shortcuts', ->
    data = {
      tests: {
        boolTrue: true
        boolFalse: false
        zero: 0
        one: 1
        emptyString: ''
        emptyObject: {}
        emptyArray: []
      }
    }
    template = """
      {{? d.tests.boolTrue }}
        <span>boolTrue</span>
      {{/}}
      {{?d.tests.one === 1}}
        <span>boolTrue</span>
      {{/}}
      {{^ d.tests.emptyString }}
        <span>emptyString</span>
      {{/}}
      {{^d.tests.zero > 0}}
        <span>zero</span>
      {{/}}
      """
    expected = '<span>boolTrue</span>' +
      '<span>boolTrue</span>' +
      '<span>emptyString</span>' +
      '<span>zero</span>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'for', ->
    data = {
      nullValue: null
      users: [
        { name: 'Jimmy' }
        { name: 'Ralph' }
        { name: 'Joe' }
      ]
    }
    template = """
      <div class="users">
        {{- for d.nullValue }}
          <!-- Should handle non-array values -->
        {{- end }}
        {{- for d.undef }}
          <!-- Should handle non-array values -->
        {{- end }}
        {{- for d.users }}
          {{- for d }}
            <!-- Won't work for objects either -->
          {{- end }}
          <div class="user">{{d.name}}</div>
        {{- end }}
      </div>
      """
    expected = '<div class="users">' +
      '<div class="user">Jimmy</div>' +
      '<div class="user">Ralph</div>' +
      '<div class="user">Joe</div>' +
      '</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'nested for', ->
    data = {
      posts: [
        {
          title: 'My Blog Post'
          comments: ['First!', 'Great!', 'I hate this.']
          images: [
            { src: '/image1.jpg' }
          ]
        }
        {
          title: 'My Crappy Blog Post'
          comments: ['Crickets.']
          images: [
            { src: '/image1.jpg' },
            { src: '/image2.jpg', alt: 'My Alt Text' },
            { src: '/image3.jpg' }
          ]
        }
      ]
    }
    template = """
      <div class="posts">
        {{- for d.posts as post }}
          <div class="post">
            <h1>{{post.title}}</h1>
            <div class="images">
              {{- for post.images as image}}
                <img src="{{image.src}}" alt="{{image.alt}}" />
              {{- end }}
            </div>
            <div class="comments">
              {{- for post.comments as comment}}
                <div class="comment">{{comment}}</div>
              {{- end }}
            </div>
          </div>
        {{- end }}
      </div>
      """
    expected = '' +
      '<div class="posts">' +
        '<div class="post">' +
          '<h1>My Blog Post</h1>' +
          '<div class="images">' +
            '<img src="/image1.jpg" alt="" />' +
          '</div>' +
          '<div class="comments">' +
            '<div class="comment">First!</div>' +
            '<div class="comment">Great!</div>' +
            '<div class="comment">I hate this.</div>' +
          '</div>' +
        '</div>' +
        '<div class="post">' +
          '<h1>My Crappy Blog Post</h1>' +
          '<div class="images">' +
            '<img src="/image1.jpg" alt="" />' +
            '<img src="/image2.jpg" alt="My Alt Text" />' +
            '<img src="/image3.jpg" alt="" />' +
          '</div>' +
          '<div class="comments">' +
            '<div class="comment">Crickets.</div>' +
          '</div>' +
        '</div>' +
      '</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'for blocks inside partials inside for blocks', ->
    data = {
      divs: [
        { uls: [ { li: 'a1' }, { li: 'a2' } ] }
        { uls: [ { li: 'b1' }, { li: 'b2' } ] }
        { uls: [ { li: 'c1' }, { li: 'c2' } ] }
      ]
    }
    template = '<div>{{- for d.divs as div }}{{- for div.uls as ul }}{{ul.li}}{{/}}{{/}}</div><div>{{- render listOfDivs }}</div>'
    expected = '<div>a1a2b1b2c1c2</div>' +
      '<div>' +
        '<div><ul><li>a1</li><li>a2</li></ul></div>' +
        '<div><ul><li>b1</li><li>b2</li></ul></div>' +
        '<div><ul><li>c1</li><li>c2</li></ul></div>' +
      '</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'deeply nested for blocks with if blocks', ->
    data = {
      arr: [ [ [ [ [ 'a1', 'a2', 'a3' ], [ 'b1', 'b2', 'b3' ] ] ] ] ]
    }
    template = """
      {{- if d.arr }}
        {{- for d.arr }}
          {{_i}},
          {{- for d }}
            {{_i}},
            {{- for d }}
              {{_i}},
              {{- if d }}
                {{- for d }}
                  {{_i}},
                  {{- for d }}
                    {{d}},
                  {{/}}
                {{/}}
              {{/}}
            {{/}}
          {{/}}
        {{/}}
        {{- for d.arr as a }}
          {{- for a as a }}
            {{- for a as a }}
              {{- for a as a }}
                {{- if d }}
                  {{- for a as a }}
                    {{a}}
                  {{/}}
                {{/}}
              {{/}}
            {{/}}
          {{/}}
        {{/}}
      {{/}}
      """
    expected = '0,0,0,0,a1,a2,a3,1,b1,b2,b3,a1a2a3b1b2b3'
    expect(Caveman(template, data)).toEqual(expected)

  it 'each', ->
    data = {
      car: {
        make: 'Volvo'
        model: '245s'
        year: 1976
        color: 'Orange'
      }
    }
    template = """
      <div class="attributes">
        {{- each d.car }}
          <div class="attribute">{{_key}}: {{d}}</div>
        {{- end }}
      </div>
      """
    expected = '<div class="attributes">' +
      '<div class="attribute">make: Volvo</div>' +
      '<div class="attribute">model: 245s</div>' +
      '<div class="attribute">year: 1976</div>' +
      '<div class="attribute">color: Orange</div>' +
      '</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'nested each', ->
    data = {
      posts: [
        {
          title: 'My Blog Post'
          comments: ['First!', 'Great!', 'I hate this.']
          images: [
            { src: '/image1.jpg' }
          ]
        }
        {
          title: 'My Crappy Blog Post'
          comments: ['Crickets.']
          images: [
            { src: '/image1.jpg' },
            { src: '/image2.jpg', alt: 'My Alt Text' },
            { src: '/image3.jpg' }
          ]
        }
      ]
    }
    template = """
      <div class="posts">
        {{- each d.posts as post }}
          <div class="post">
            <h1>{{post.title}}</h1>
            <div class="images">
              {{- each post.images as image}}
                <img src="{{image.src}}" alt="{{image.alt}}" />
              {{- end }}
            </div>
            <div class="comments">
              {{- each post.comments as comment}}
                {{- if _key === 0 }}
                  <span>{{d.posts.length}} posts</span>
                {{- end }}
                <div class="comment">{{comment}}</div>
              {{- end }}
            </div>
          </div>
        {{- end }}
      </div>
      """
    expected = '' +
      '<div class="posts">' +
        '<div class="post">' +
          '<h1>My Blog Post</h1>' +
          '<div class="images">' +
            '<img src="/image1.jpg" alt="" />' +
          '</div>' +
          '<div class="comments">' +
            '<span>2 posts</span>' +
            '<div class="comment">First!</div>' +
            '<div class="comment">Great!</div>' +
            '<div class="comment">I hate this.</div>' +
          '</div>' +
        '</div>' +
        '<div class="post">' +
          '<h1>My Crappy Blog Post</h1>' +
          '<div class="images">' +
            '<img src="/image1.jpg" alt="" />' +
            '<img src="/image2.jpg" alt="My Alt Text" />' +
            '<img src="/image3.jpg" alt="" />' +
          '</div>' +
          '<div class="comments">' +
            '<span>2 posts</span>' +
            '<div class="comment">Crickets.</div>' +
          '</div>' +
        '</div>' +
      '</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'with', ->
    data = {
      foo: {
        a: 123
        b: 234
      }
    }
    template = """
      {{- with d.foo }}
        <span>a: {{d.a}}</span>
        <span>b: {{d.b}}</span>
      {{- end }}
      {{- with d.foo as foo }}
        <span>a: {{foo.a}}</span>
        <span>b: {{foo.b}}</span>
      {{- end }}
      """
    expected = '<span>a: 123</span><span>b: 234</span><span>a: 123</span><span>b: 234</span>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'script execution', ->
    data = {
      rows: [ 1, 2, 3, 4, 5 ]
    }
    template = """
      <table>
      {{- for d.rows }}
        {{- everyThirdStripe = [_i % 3 ? '': 'zebra-stripe'] }}
        <tr class="{{everyThirdStripe}}">
          <td>{{d}}</td>
        </tr>
      {{- end }}
      </table>
      """
    expected = '<table>' +
      '<tr class="zebra-stripe"><td>1</td></tr>' +
      '<tr class=""><td>2</td></tr>' +
      '<tr class=""><td>3</td></tr>' +
      '<tr class="zebra-stripe"><td>4</td></tr>' +
      '<tr class=""><td>5</td></tr>' +
      '</table>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'print', ->
    data = {
      rows: [ 1, 2, 3 ]
    }
    template = """
      {{- for d.rows }}
        <div>{{d}} x {{d}} = {{- print d * d }}</div>
      {{- end }}
      """
    expected = '<div>1 x 1 = 1</div>' +
      '<div>2 x 2 = 4</div>' +
      '<div>3 x 3 = 9</div>'
    expect(Caveman(template, data)).toEqual(expected)

describe 'Escaping', ->

  it 'does not escape by default', ->
    data = {
      html: '<script>alert("HELLO XSS!");</script> & \''
    }
    template = '<div>{{d.html}}</div>'
    expected = '<div><script>alert("HELLO XSS!");</script> & \'</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'escape macro', ->
    data = {
      html: '<script>alert("HELLO XSS!");</script> & \''
    }
    template = '<div>{{- escape d.html }}</div>'
    expected = '<div>&lt;script&gt;alert(&quot;HELLO XSS!&quot;);&lt;/script&gt; &amp; &#39;</div>'
    expect(Caveman(template, data)).toEqual(expected)

  it 'escape macro will not double-escape if escapeByDefault is true', ->
    data = {
      html: '<script>alert("HELLO XSS!");</script> & \''
    }
    template = '<div>{{- escape d.html }}</div>'
    expected = '<div>&lt;script&gt;alert(&quot;HELLO XSS!&quot;);&lt;/script&gt; &amp; &#39;</div>'
    Caveman.options.escapeByDefault = true
    expect(Caveman(template, data)).toEqual(expected)

  it 'escapes by default using the escapeByDefault option', ->
    data = {
      html: '<script>alert("HELLO XSS!");</script> & \''
    }
    template = '<div>{{d.html}}</div>'
    expected = '<div>&lt;script&gt;alert(&quot;HELLO XSS!&quot;);&lt;/script&gt; &amp; &#39;</div>'
    Caveman.options.escapeByDefault = true
    expect(Caveman(template, data)).toEqual(expected)
