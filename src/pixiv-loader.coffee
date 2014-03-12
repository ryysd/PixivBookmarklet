# extract number from string
extractNum = (str) ->
  num = (new String str).match /\d/g
  num.join('') if num?

# debug 
class Debug
  @print: (html) -> ($ 'html').html html

class PixivURL
  @host = 'http://www.pixiv.net'
  @actions = 
    login: 'login.php'
    bookmark: 'bookmark.php'
    memberIllust: 'member_illust.php'

  @makeURL : (action) -> "#{@host}/#{@actions[action]}"

class PixivParser
  @parseBookmarkPage: (html) ->
    $page = $ html

    $count = ($page.find '.column-label').find '.count-badge'
    $illusts = ($page.find '.display_works').find 'li'

    $next = $page.find '.sprites-next-linked'
    $prev = $page.find '.sprites-prev-linked'

    $current = $((($page.find '.page-list').children ' .current')[0])

    count = extractNum $count.text()

    illusts = ({
      id: extractNum ((($ illust).find '.work').attr 'href')
      title: (($ illust).find '.work').text() 
      tags: (($ illust).find 'img').attr 'data-tags'
      author: ''
    } for illust in $illusts when (($ illust).find 'img').length)

    {
      count: count, 
      illusts: illusts, 
      current: (parseInt $current.text()),
      hasNext: $next.length != 0, 
      hasPrev: $prev.length != 0
    }

  @parseMemberIllustPage: (html) ->
    PixivParser.parseBookmarkPage html

  @parseIllustPage: (html) ->
    $page = $ html

    $image = (($page.find '.works_display').find 'img')
    mode = (($image.parent().attr 'href').match /mode=([^&]*)/)[1]
    author = ($page.find '.user').text()

    url = ($image.attr 'src').replace '_m', ''

    {image: url, author: author, mode: mode}

  @parseMangaPage: (html) ->
    $page = $ html

    $items = $page.find '.item-container'
    images = ((($ item).find 'img').attr 'data-src').replace /p([0-9]+)/, 'big_p$1' for item in $items

class PixivBookmarklet
  constructor: () ->

  @downloadIllust = (illust, url) ->
    ext = (url.split '.').pop()

    title = "#{illust.author}_#{illust.title}(#{illust.id}).#{ext}"
    downloadFile url, title

  @downloadManga: (illust, url) ->
    $.get (PixivBookmarklet.makeMangaPageUrlFromId illust.id), null, (data) -> 
      images = PixivParser.parseMangaPage(data)
      for img in images
        PixivBookmarklet.downloadIllust illust, img

  @getImageUrlFromIllustPage = (url, callback) ->
    $.get url, null, (data) -> callback(PixivParser.parseIllustPage data)

  @makeIllustPageUrlFromId = (id) -> (PixivURL.makeURL 'memberIllust') + '?mode=medium&illust_id=' + id
  @makeMangaPageUrlFromId = (id) -> (PixivURL.makeURL 'memberIllust') + '?mode=manga&illust_id=' + id
  @makeIllustPageUrlsFromIllusts = (illusts) -> (PixivBookmarklet.makeIllustPageUrlFromId illust.id for illust in illusts when illust.id?)

  @downloadIllusts: (illusts, options) ->
    latency = if options? && options.latency? then options.latency else 0 

    urls = PixivBookmarklet.makeIllustPageUrlsFromIllusts illusts 

    _downloadIllusts = (idx) ->
      if idx < urls.length 
        next = idx + 1
        PixivBookmarklet.getImageUrlFromIllustPage urls[idx], (url) ->
          dl = if url.mode == 'manga' then PixivBookmarklet.downloadManga else PixivBookmarklet.downloadIllust

          illust = illusts[idx]
          illust.author = url.author

          dl illust, url.image
          options.progress url, idx if options? && options.progress? 

          # insert latency for server load reduction
          _rec = () -> _downloadIllusts next
          setTimeout _rec, latency

    _downloadIllusts 0

  @downloadIllustsWithProgress: (illusts) ->
    progress = new LoaderProgressBox()
    $modal = progress.show()

    cnt = 0
    onEnd = () -> $modal.modal 'hide'
    onProgress = (url) -> 
      progress.setProgress ++cnt, illusts.length
      onEnd() if cnt >= illusts.length

    PixivBookmarklet.downloadIllusts illusts, progress: onProgress

  @readSequentialPage: (url, from, to, options) ->

  @downloadAllBookmarkIllusts: (html, options) ->
    done = []

    _downloadAllBookmarkIllusts = (_html) ->
      result = PixivBookmarklet.downloadBookmarkIllusts _html, options
      done[result.current] = true

      if result.hasNext && !done[result.current + 1]
        $.get location.href + "&p=#{result.current + 1}", null, (data) -> _downloadAllBookmarkIllusts data
      if result.hasPrev && !done[result.current - 1]
        $.get location.href + "&p=#{result.current - 1}", null, (data) -> _downloadAllBookmarkIllusts data

    _downloadAllBookmarkIllusts html

  @downloadBookmarkIllusts: (html, options) ->
    result = PixivParser.parseBookmarkPage html
    illusts = result.illusts

    if options? && options.showProgress then PixivBookmarklet.downloadIllustsWithProgress illusts
    else PixivBookmarklet.downloadIllusts illusts

    result

  @downloadMemberIllusts: (html, options) ->
    PixivBookmarklet.downloadBookmarkIllusts html, options

  @isBookmarkPage: () ->
    location.href.indexOf(PixivURL.makeURL 'bookmark') != -1

  @isMemberIllustPage: () ->
    location.href.indexOf(PixivURL.makeURL 'memberIllust') != -1

class BootProgress
  constructor: (options) ->
    @$progress = ($ '<div></div>').attr 'class', 'progress progress-striped active'
    @$progressBar = ($ '<div></div>').attr class: "progress-bar progress-bar-#{options.type || 'success'}", role: 'progressbar'
    @$progressBar.css 'width', '0%'
    @$text =($ '<span></span>')

    @$progress.append (@$progressBar.append @$text)

  setText: (text) -> @$text.text text
  setPercentage: (per) -> @$progressBar.css 'width', "#{per}%"

  appendTo: ($parent) -> $parent.append @$progress

class BootBox
  @show: (content, title, options) ->
    $modalBody = ($ '<div></div>').attr 'class', 'modal-body'
    $modalBody.append content 

    $modalHeader =
      (($ '<div></div>').attr 'class', 'modal-header')
        .append((($ '<button></button>').attr type: 'button', class: 'close', 'data-dismiss': 'modal').text '×')
        .append((($ '<h4></h4>').attr 'class', 'modal-title').text title)

    $modalFooter = 
      ($ '<div></div').attr('class', 'modal-footer')
        .append '<button data-bb-handler="cancel" type="button" class="btn btn-danger">cancel</button>'

    $modal =
      ($ '<div></div>').attr class: 'modal fade', tabIndex: '-1', role: 'dialog'

     $modalDialog = $('<div></div>').attr('class', 'modal-dialog')
     $modalContent = $('<div></div>').attr('class', 'modal-content')

     $modalContent.append $modalHeader
     $modalContent.append $modalBody
     $modalContent.append $modalFooter

     $modalDialog.append $modalContent
     $modal.append $modalDialog

     $modal.on 'hidden.bs.modal', () =>  $modal.remove()

     $modal.modal show: true

     $modal

class LoaderProgressBox
  constructor: () ->
    @progress = new BootProgress type: 'success'

    @$content = $ '<div></div>'

    $label = ($ '<span></span>').attr 'class', 'col-md-3'
    $label = 'progress'

    @progress.$progress.attr 'class', 'col-md-9'

    @$content.append $label
    @$content.append @progress.$progress 

  setProgress: (now, max) ->
    @progress.setText "#{now}/#{max} Complete"
    @progress.setPercentage ~~(now * 100 / max)

  show: () ->
    BootBox.show @$content, 'Now Downloading...'

# load dependent files
loadDependencies = ->
  _loadScript = (url) ->
    s = $ '<script></script>'
    s.attr charset: 'UTF-8', type: 'text/javascript', src: url
    ($ 'head').append s

  _loadCSS = (url) ->
    s = $ '<link></link>'
    s.attr rel: 'stylesheet', type: 'text/css', href: url
    ($ 'head').append s

  _loadScript 'http://localhost/PixivWebPageParser/src/download.js'
  _loadCSS 'http://localhost/PixivWebPageParser/css/btn-design.css'
  #_loadScript 'http://localhost/PixivWebPageParser/src/bootstrap.min.js'
  #_loadScript 'http://localhost/PixivWebPageParser/src/bootbox.min.js'
  #_loadCSS 'http://localhost/PixivWebPageParser/css/bootstrap.min.css'

insertButton = ->
  $target = $ '.column-menu'
  $ul = ($ '<ul></ul>').attr 'class', 'menu-items'
  $li = ($ '<li></li>')
  $dlBtn = (($ '<div></div>').attr 'class', 'btn btn-success').text('このページをダウンロード')
  $alldlBtn = (($ '<div></div>').attr 'class', 'btn btn-primary').text('全てダウンロード')

  $dlBtn.click () -> PixivBookmarklet.downloadBookmarkIllusts document, showProgress:false
  $alldlBtn.click () -> PixivBookmarklet.downloadAllBookmarkIllusts document, showProgress: false

  $li.append $dlBtn
  $li.append $alldlBtn
  $ul.append $li
  $target.append $ul

$ ->
  loadDependencies()

  insertButton()

  #if PixivBookmarklet.isBookmarkPage()
  #  PixivBookmarklet.downloadBookmarkIllusts document, showProgress: false
  #else if PixivBookmarklet.isMemberIllustPage()
  #  PixivBookmarklet.downloadMemberIllusts document, showProgress: false
