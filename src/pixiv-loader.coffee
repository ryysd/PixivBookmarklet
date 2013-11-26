class Debug
  @print: (html) -> ($ 'html').html html

class PixivURL
  @host = 'http://www.pixiv.net'
  @actions = 
    login: 'login.php'
    bookmark: 'bookmark.php'
    memberIllust: 'member_illust.php'

  @makeURL : (action) -> "#{@host}/#{@actions[action]}"

###
class PixivReader
  constructor: (@id, @pass) ->

  get: (action, data, callback) ->
    jqxhr = $.get (PixivURL.makeURL action), data, () -> (callback jqxhr)

  post: (action, data, callback) ->
    jqxhr = $.post (PixivURL.makeURL action), data, () -> (callback jqxhr)

  login: (callback) ->
    @post 'login', {pixiv_id: @id, pass: @pass, mode: 'login', 'skip': '0'}, callback

  getBookmarkPage: (callback, options) ->
    data = {}

    if options?
      data.rest = if options.hidden? then 'hide' else 'show'
      data.p = options.page if options.page?

    @post 'bookmark', data, callback

  getIllustPage: (id, callback) ->
    $.ajax({
      type : 'GET'
      url : PixivURL.makeURL 'memberIllust'
      data : {mode: 'big', illust_id: id}
      beforeSend : (jqxhr)  -> jqxhr.setRequestHeader 'Referer', PixivURL.host
      complete : callback 
    })
###

class PixivParser
  @parseBookmarkPage: (html) ->
    $page = $ html

    $count = ($page.find '.column-label').find '.count-badge'
    $illusts = ($page.find '.display_works').find 'li'

    $next = $page.find '.sprites-next-linked'
    $prev = $page.find '.sprites-prev-linked'

    count = parseInt $count.text()

    illusts = ({
      id: ((($ illust).attr 'id').replace 'li_', ''), 
      title: (($ illust).find '.work').text() ,
      tags: (($ illust).find 'img').attr 'data-tags'
    } for illust in $illusts when (($ illust).find 'img').length)

    {
      count: count, 
      illusts: illusts, 
      hasNext: $next.length != 0, 
      hasPrev: $prev.length != 0
    }

class PixivAPI
  constructor: (id, pass) ->
    @reader = new PixivReader(id, pass)

  login: (callback) ->
    @reader.login(callback)

  getBookmarkIllusts: (hidden, callback) ->

class PixivBookmarklet
  constructor: () ->

  @isBookmarkPage: () ->
    location.href.indexOf(PixivURL.makeURL 'bookmark') != -1

  @isMemberIllustPage: () ->
    location.href.indexOf(PixivURL.makeURL 'bookmark') != -1

$ ->
  if PixivBookmarklet.isBookmarkPage()
    illusts = PixivParser.parseBookmarkPage document
    console.log illusts

test = (id, pass) ->
  reader = new PixivReader(id, pass)

  reader.login((jq) -> 
    bookmark = reader.getIllustPage('39909714', (jqxhr) ->
      Debug.print jqxhr.responseText
      # data = PixivParser.parseBookmarkPage(jqxhr.responseText)
    )
  )

