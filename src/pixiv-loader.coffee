# extract number from string
extractNum = (str) ->
  num = (new String str).match /\d/g;
  num.join('');

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

    count = extractNum $count.text()

    illusts = ({
      id: extractNum ((($ illust).find '.work').attr 'href')
      title: (($ illust).find '.work').text() 
      tags: (($ illust).find 'img').attr 'data-tags'
    } for illust in $illusts when (($ illust).find 'img').length)

    {
      count: count, 
      illusts: illusts, 
      hasNext: $next.length != 0, 
      hasPrev: $prev.length != 0
    }

  @parseMemberIllustPage: (html) ->
    PixivParser.parseBookmarkPage html

  @parseIllustPage: (html) ->
    $page = $ html

    $image = (($page.find '.works_display').find 'img')
    url = ($image.attr 'src').replace '_m', ''

    {image: url}

class PixivBookmarklet
  constructor: () ->

  @downloadIllust = (title, url) ->
    ext = (url.split '.').pop()

    title = title + ".#{ext}"
    downloadFile url, title

  @getImageUrlFromIllustPage = (url, callback) ->
    $.get url, null, (data) -> callback(PixivParser.parseIllustPage data)

  @makeIllustPageUrlFromId = (id) -> (PixivURL.makeURL 'memberIllust') + '?mode=medium&illust_id=' + id
  @makeIllustPageUrlsFromIllusts = (illusts) -> (PixivBookmarklet.makeIllustPageUrlFromId illust.id for illust in illusts)

  @downloadIllusts: (illusts, options) ->
    urls = PixivBookmarklet.makeIllustPageUrlsFromIllusts illusts 

    _downloadIllusts = (idx) ->
      if idx < urls.length 
        next = idx + 1
        PixivBookmarklet.getImageUrlFromIllustPage urls[idx], (url) ->
          _downloadIllusts next

          PixivBookmarklet.downloadIllust illusts[idx].title, url.image
          options.progress url, idx if options? && options.progress? 

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

  @downloadBookmarkIllusts: (html, options) ->
    result = PixivParser.parseBookmarkPage html
    illusts = result.illusts

    if options? && options.showProgress then PixivBookmarklet.downloadIllustsWithProgress illusts
    else PixivBookmarklet.downloadIllusts illusts

  @downloadMemberIllusts: (html, options) ->
    result = PixivParser.parseMemberIllustPage html
    illusts = result.illusts

    PixivBookmarklet.downloadIllusts illusts

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
    @progress.appendTo @$content

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
  _loadScript 'http://localhost/PixivWebPageParser/src/bootstrap.min.js'
  _loadScript 'http://localhost/PixivWebPageParser/src/bootbox.min.js'
  _loadCSS 'http://localhost/PixivWebPageParser/css/bootstrap.min.css'

$ ->
  loadDependencies()

  if PixivBookmarklet.isBookmarkPage()
    PixivBookmarklet.downloadBookmarkIllusts document, showProgress: true
  else if PixivBookmarklet.isMemberIllustPage()
    PixivBookmarklet.downloadMemberIllusts document
