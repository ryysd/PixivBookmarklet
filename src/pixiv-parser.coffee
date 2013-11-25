class Debug
  @print: (html) -> ($ 'html').html html

class PixivURL
  @host = 'http://www.pixiv.net'
  @actions = 
    login: 'login.php'

  @makeURL : (action) -> @host + '/' + @actions[action]

class PixivReader
  constructor: (@id, @pass) ->

  get: (action, data, callback) ->
    $.get (PixivURL.makeURL action), data, callback

  post: (action, data, callback) ->
    $.post (PixivURL.makeURL action), data, callback

  login: (callback) ->
    @post 'login', {pixiv_id: @id, pass: @pass, mode: 'login', 'skip': '0'}, callback

class PixivParser
