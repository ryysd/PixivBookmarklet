// Generated by CoffeeScript 1.6.3
var BootBox, BootProgress, Debug, LoaderProgressBox, PixivBookmarklet, PixivParser, PixivURL, extractNum, loadDependencies;

extractNum = function(str) {
  var num;
  num = (new String(str)).match(/\d/g);
  return num.join('');
};

Debug = (function() {
  function Debug() {}

  Debug.print = function(html) {
    return ($('html')).html(html);
  };

  return Debug;

})();

PixivURL = (function() {
  function PixivURL() {}

  PixivURL.host = 'http://www.pixiv.net';

  PixivURL.actions = {
    login: 'login.php',
    bookmark: 'bookmark.php',
    memberIllust: 'member_illust.php'
  };

  PixivURL.makeURL = function(action) {
    return "" + this.host + "/" + this.actions[action];
  };

  return PixivURL;

})();

PixivParser = (function() {
  function PixivParser() {}

  PixivParser.parseBookmarkPage = function(html) {
    var $count, $illusts, $next, $page, $prev, count, illust, illusts;
    $page = $(html);
    $count = ($page.find('.column-label')).find('.count-badge');
    $illusts = ($page.find('.display_works')).find('li');
    $next = $page.find('.sprites-next-linked');
    $prev = $page.find('.sprites-prev-linked');
    count = extractNum($count.text());
    illusts = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = $illusts.length; _i < _len; _i++) {
        illust = $illusts[_i];
        if ((($(illust)).find('img')).length) {
          _results.push({
            id: extractNum((($(illust)).find('.work')).attr('href')),
            title: (($(illust)).find('.work')).text(),
            tags: (($(illust)).find('img')).attr('data-tags')
          });
        }
      }
      return _results;
    })();
    return {
      count: count,
      illusts: illusts,
      hasNext: $next.length !== 0,
      hasPrev: $prev.length !== 0
    };
  };

  PixivParser.parseMemberIllustPage = function(html) {
    return PixivParser.parseBookmarkPage(html);
  };

  PixivParser.parseIllustPage = function(html) {
    var $image, $page, url;
    $page = $(html);
    $image = ($page.find('.works_display')).find('img');
    url = ($image.attr('src')).replace('_m', '');
    return {
      image: url
    };
  };

  return PixivParser;

})();

PixivBookmarklet = (function() {
  function PixivBookmarklet() {}

  PixivBookmarklet.downloadIllust = function(title, url) {
    var ext;
    ext = (url.split('.')).pop();
    title = title + ("." + ext);
    return downloadFile(url, title);
  };

  PixivBookmarklet.getImageUrlFromIllustPage = function(url, callback) {
    return $.get(url, null, function(data) {
      return callback(PixivParser.parseIllustPage(data));
    });
  };

  PixivBookmarklet.makeIllustPageUrlFromId = function(id) {
    return (PixivURL.makeURL('memberIllust')) + '?mode=medium&illust_id=' + id;
  };

  PixivBookmarklet.makeIllustPageUrlsFromIllusts = function(illusts) {
    var illust, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = illusts.length; _i < _len; _i++) {
      illust = illusts[_i];
      _results.push(PixivBookmarklet.makeIllustPageUrlFromId(illust.id));
    }
    return _results;
  };

  PixivBookmarklet.downloadIllusts = function(illusts, options) {
    var urls, _downloadIllusts;
    urls = PixivBookmarklet.makeIllustPageUrlsFromIllusts(illusts);
    _downloadIllusts = function(idx) {
      var next;
      if (idx < urls.length) {
        next = idx + 1;
        return PixivBookmarklet.getImageUrlFromIllustPage(urls[idx], function(url) {
          _downloadIllusts(next);
          PixivBookmarklet.downloadIllust(illusts[idx].title, url.image);
          if ((options != null) && (options.progress != null)) {
            return options.progress(url, idx);
          }
        });
      }
    };
    return _downloadIllusts(0);
  };

  PixivBookmarklet.downloadIllustsWithProgress = function(illusts) {
    var $modal, cnt, onEnd, onProgress, progress;
    progress = new LoaderProgressBox();
    $modal = progress.show();
    cnt = 0;
    onEnd = function() {
      return $modal.modal('hide');
    };
    onProgress = function(url) {
      progress.setProgress(++cnt, illusts.length);
      if (cnt >= illusts.length) {
        return onEnd();
      }
    };
    return PixivBookmarklet.downloadIllusts(illusts, {
      progress: onProgress
    });
  };

  PixivBookmarklet.downloadBookmarkIllusts = function(html, options) {
    var illusts, result;
    result = PixivParser.parseBookmarkPage(html);
    illusts = result.illusts;
    if ((options != null) && options.showProgress) {
      return PixivBookmarklet.downloadIllustsWithProgress(illusts);
    } else {
      return PixivBookmarklet.downloadIllusts(illusts);
    }
  };

  PixivBookmarklet.downloadMemberIllusts = function(html, options) {
    var illusts, result;
    result = PixivParser.parseMemberIllustPage(html);
    illusts = result.illusts;
    return PixivBookmarklet.downloadIllusts(illusts);
  };

  PixivBookmarklet.isBookmarkPage = function() {
    return location.href.indexOf(PixivURL.makeURL('bookmark')) !== -1;
  };

  PixivBookmarklet.isMemberIllustPage = function() {
    return location.href.indexOf(PixivURL.makeURL('memberIllust')) !== -1;
  };

  return PixivBookmarklet;

})();

BootProgress = (function() {
  function BootProgress(options) {
    this.$progress = ($('<div></div>')).attr('class', 'progress progress-striped active');
    this.$progressBar = ($('<div></div>')).attr({
      "class": "progress-bar progress-bar-" + (options.type || 'success'),
      role: 'progressbar'
    });
    this.$progressBar.css('width', '0%');
    this.$text = $('<span></span>');
    this.$progress.append(this.$progressBar.append(this.$text));
  }

  BootProgress.prototype.setText = function(text) {
    return this.$text.text(text);
  };

  BootProgress.prototype.setPercentage = function(per) {
    return this.$progressBar.css('width', "" + per + "%");
  };

  BootProgress.prototype.appendTo = function($parent) {
    return $parent.append(this.$progress);
  };

  return BootProgress;

})();

BootBox = (function() {
  function BootBox() {}

  BootBox.show = function(content, title, options) {
    var $modal, $modalBody, $modalContent, $modalDialog, $modalFooter, $modalHeader,
      _this = this;
    $modalBody = ($('<div></div>')).attr('class', 'modal-body');
    $modalBody.append(content);
    $modalHeader = (($('<div></div>')).attr('class', 'modal-header')).append((($('<button></button>')).attr({
      type: 'button',
      "class": 'close',
      'data-dismiss': 'modal'
    })).text('×')).append((($('<h4></h4>')).attr('class', 'modal-title')).text(title));
    $modalFooter = ($('<div></div')).attr('class', 'modal-footer').append('<button data-bb-handler="cancel" type="button" class="btn btn-danger">cancel</button>');
    $modal = ($('<div></div>')).attr({
      "class": 'modal fade',
      tabIndex: '-1',
      role: 'dialog'
    });
    $modalDialog = $('<div></div>').attr('class', 'modal-dialog');
    $modalContent = $('<div></div>').attr('class', 'modal-content');
    $modalContent.append($modalHeader);
    $modalContent.append($modalBody);
    $modalContent.append($modalFooter);
    $modalDialog.append($modalContent);
    $modal.append($modalDialog);
    $modal.on('hidden.bs.modal', function() {
      return $modal.remove();
    });
    $modal.modal({
      show: true
    });
    return $modal;
  };

  return BootBox;

})();

LoaderProgressBox = (function() {
  function LoaderProgressBox() {
    this.progress = new BootProgress({
      type: 'success'
    });
    this.$content = $('<div></div>');
    this.progress.appendTo(this.$content);
  }

  LoaderProgressBox.prototype.setProgress = function(now, max) {
    this.progress.setText("" + now + "/" + max + " Complete");
    return this.progress.setPercentage(~~(now * 100 / max));
  };

  LoaderProgressBox.prototype.show = function() {
    return BootBox.show(this.$content, 'Now Downloading...');
  };

  return LoaderProgressBox;

})();

loadDependencies = function() {
  var _loadCSS, _loadScript;
  _loadScript = function(url) {
    var s;
    s = $('<script></script>');
    s.attr({
      charset: 'UTF-8',
      type: 'text/javascript',
      src: url
    });
    return ($('head')).append(s);
  };
  _loadCSS = function(url) {
    var s;
    s = $('<link></link>');
    s.attr({
      rel: 'stylesheet',
      type: 'text/css',
      href: url
    });
    return ($('head')).append(s);
  };
  _loadScript('http://localhost/PixivWebPageParser/src/download.js');
  _loadScript('http://localhost/PixivWebPageParser/src/bootstrap.min.js');
  _loadScript('http://localhost/PixivWebPageParser/src/bootbox.min.js');
  return _loadCSS('http://localhost/PixivWebPageParser/css/bootstrap.min.css');
};

$(function() {
  loadDependencies();
  if (PixivBookmarklet.isBookmarkPage()) {
    return PixivBookmarklet.downloadBookmarkIllusts(document, {
      showProgress: true
    });
  } else if (PixivBookmarklet.isMemberIllustPage()) {
    return PixivBookmarklet.downloadMemberIllusts(document);
  }
});
