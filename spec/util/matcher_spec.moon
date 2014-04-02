import Matcher from howl.util

describe 'Matcher(candidates)', ->

  it 'matches if the search matches exactly', ->
    c = { 'One', 'Green Fields', 'two' }
    m = Matcher c
    assert.same { 'One' }, m('ne')

  describe '(boundary matches)', ->

    it 'matches if the search matches at boundaries', ->
      c = { 'green fields', 'green sfinx' }
      m = Matcher c
      assert.same { 'green fields' }, m('gf')
      assert.same { 'apaass_so' }, Matcher({'apaass_so'})('as')

    it 'matches if the search matches at upper case boundaries', ->
      c = { 'camelCase', 'a CreditCard', 'chacha' }
      m = Matcher c
      assert.same { 'camelCase', 'a CreditCard' }, m('cc')

  it 'candidates are automatically converted to strings', ->
    candidate = setmetatable {}, __tostring: -> 'auto'
    m = Matcher { candidate }
    assert.same { candidate }, m('auto')

  it 'candidates can be multi-valued tables', ->
    c = { { 'One', 'Uno' } }
    m = Matcher c
    assert.same { c[1] }, m('One')

  it 'multi-valued candidates are automatically converted to strings', ->
    candidate = setmetatable {}, __tostring: -> 'auto'
    m = Matcher { { candidate, 'desc' } }
    assert.same { { candidate, 'desc' } }, m('auto')

  it 'prefers boundary matches over exact ones', ->
    c = { 'kiss her', 'some/stuff/here', 'openssh', 'sss hhh' }
    m = Matcher c
    assert.same {
      'sss hhh',
      'some/stuff/here'
      'openssh',
    }, m('ssh')

  it 'prefers early occurring matches over ones at the end', ->
    c = { 'Discard all apples', 'all aardvarks' }
    m = Matcher c
    assert.same {
      'all aardvarks',
      'Discard all apples'
    }, m('aa')

  it 'prefers shorter matching candidates over longer ones', ->
    c = { 'x/tools.sh', 'x/torx' }
    m = Matcher c
    assert.same {
      'x/torx',
      'x/tools.sh'
    }, m('to')

  it 'prefers tighter matches to longer ones', ->
    c = { 'awesome_apples', 'an_aardvark'  }

    m = Matcher c
    assert.same {
      'an_aardvark',
      'awesome_apples',
    }, m('aa')

  it '"special" characters are matched as is', ->
    c = { 'Item 2. 1%w', 'Item 22 2a' }
    m = Matcher c
    assert.same { 'Item 2. 1%w' }, m('%w')
    assert.same { }, m('.*')

  it 'boundary matches can not skip separators', ->
    m = Matcher { 'nih/says/knights' }
    assert.same { 'nih/says/knights' }, m('sk')
    assert.same {}, m('nk')

  describe 'explain(search, text)', ->
    it 'sets .how to the type of match', ->
      assert.equal 'exact', Matcher.explain('fu', 'snafu').how

    it 'returns a list of character offsets indicating where <search> matched', ->
      assert.same { how: 'exact', 4, 5, 6 }, Matcher.explain 'ƒlu', 'sñaƒlux'
      assert.same { how: 'boundary', 1, 4, 9, 10 }, Matcher.explain 'itʂo', 'iʂ that ʂo'

    it 'lower-cases the search and text just as for matching', ->
      assert.not_nil Matcher.explain 'FU', 'ʂnafu'
      assert.not_nil Matcher.explain 'fu', 'SNAFU'

    it 'accepts ustring both for <search> and <text>', ->
      assert.not_nil Matcher.explain 'FU', 'snafu'

  it 'boundary matches are as tight as possible', ->
    assert.same { how: 'boundary', 1, 6, 7 }, Matcher.explain 'hth', 'hail the howl'

  describe 'with reverse matching (reverse = true specified as an option)', ->
    it 'handles boundary matches', ->
      m = Matcher { 'spec/aplication_spec.moon' }, reverse: true
      assert.same { 'spec/aplication_spec.moon' }, m('as')

    it 'prefers late occurring exact matches over ones at the start', ->
      c = { 'xmatch me', 'me xmatch' }
      m = Matcher c, reverse: true
      assert.same {
        'me xmatch'
        'xmatch me',
      }, m('mat')

    it 'prefers late occurring boundary matches over ones at the start', ->
      c = { 'match natchos', 'me match now' }
      m = Matcher c, reverse: true
      assert.same {
        'me match now'
        'match natchos',
      }, m('mn')

    it 'still prefers tighter matches to longer ones', ->
      c = { 'an_aardvark', 'a_apple' }

      m = Matcher c, reverse: true
      assert.same {
        'a_apple',
        'an_aardvark',
      }, m('aa')

    it 'still prefers boundary matches over straight ones', ->
      c = { 'some/stuff/here', 'sshopen', 'open/ssh', 'ss xh' }
      m = Matcher c, reverse: true

      assert.same {
        'open/ssh',
        'sshopen',
        'some/stuff/here'
      }, m('ssh')

    it 'explain(search, text) works correctly', ->
      assert.same { how: 'exact', 7, 8, 9 }, Matcher.explain 'aƒl', 'ƒluxsñaƒlux', reverse: true
      assert.same { how: 'boundary', 1, 5 }, Matcher.explain 'as', 'app_spec.fu', reverse: true

  describe 'with preserve_order = true specified as an option', ->
    it 'preserves order of matches, irrespective of match score', ->
      c = {'xabx0', 'ax_bx1', 'xabx2', 'ax_bx3'}
      m = Matcher c, preserve_order: true
      assert.same c, m('ab')
