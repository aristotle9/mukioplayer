# coding=utf-8
#超级管理员管理页面
import logging
from datetime import timedelta,datetime

from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app

from models.article import Article
from models.video import Video
from common.base import BaseRequestHandler,_DEBUG,_404
from common.tools import Pager,MukioTools
from common.json import read

PERPAGE = 30
LINKDISTANCE = 6

class AdminPage(BaseRequestHandler):
  def get(self,pagenum = 0):
    totle = Article.all().count()
    pg = Pager(int(pagenum),PERPAGE,LINKDISTANCE,totle)
    articles = Article.all().order('-postdate').fetch(pg.len,pg.frm)
    def addkey(i):
      i.keyname = i.key().name()
      i.tagname = MukioTools.tagname(i.classify)
      i.postdate += timedelta(hours=+8)
      return i
    self.render('admin/articles.html',{'pg':pg,'articles':map(addkey,articles)})

class AdminEdit(BaseRequestHandler):
  def get(self,articlekey=None):
    article = Article.get_by_key_name(unicode(articlekey).strip())
    if not article:
      self.redirect('/admin/error')
    article.keyname = article.key().name()
    article.tagname = MukioTools.tagname(article.classify)
    article.postdate += timedelta(hours=+8)
    article.tagstring = ' '.join(article.tags)
    videos = article.video_set
    videos.order('postdate')
    def addkey(i):
      i.keyname = i.key().name()
      return i
    self.render('admin/article_edit.html',{'title':u'编辑主题','article':article,'videos':map(addkey,videos)})
  def post(self,articlekey=None):
    article = Article.get_by_key_name(unicode(articlekey).strip())
    if not article:
      self.redirect('/admin/error')
    title = unicode(self.request.get('title')).strip()
    abs = unicode(self.request.get('abs')).strip()
    tags = unicode(self.request.get('tags')).strip()
    classify = int(self.request.get('classify'))
    article.title = title;
    article.abs = abs;
    article.classify = classify;
    article.tags = tags.split();
    try:
      article.put()
    except:
      self.redirect('/admin/error/failtosavearticle')
      
    try:
      videostring = unicode(self.request.get('videolist')).strip()
      # logging.info('%r' % videostring)
      videos = read(videostring)
      # logging.info('%r' % videos)
      oldvideos = article.video_set.order('postdate')
      self.compareAndUpdate(article,videos,oldvideos)
    except:
      self.redirect('/admin/error/failtosavevideos')
    self.get(articlekey)
  def compareAndUpdate(self,article,videos,oldvideos):
    def addkey(i):
      i.keyname = i.key().name()
      return i
    oldvideos = map(addkey,oldvideos)
    for video in videos:
      # logging.info('video:%r' % video)
      flag = 0
      if video[3] != '0':
        for v in oldvideos:
          if v.keyname == video[3]:
            if v.typ !='video' and v.typ !='sound' and v.keyname != video[2] and v.keyname != 'vid'+video[2]:
              MukioTools.delete_video_by_key_name(v.keyname)
              try:
                newvideo = Video(key_name = 'vid'+video[2],
                                 parttitle = video[0],
                                 fileurl = '',
                                 vid = video[2],
                                 typ = video[1],
                                 art = article.key())
                newvideo.put()
              except:
                logging.info('插入视频失败 %r' % (video))
            else:
              v.parttitle = video[0]
              v.typ = video[1]
              if v.typ == 'video' or v.typ == 'sound':
                v.fileurl = video[2]
                v.vid = ''
              else:
                v.fileurl = ''
                v.vid = video[2]
              v.postdate = datetime.now()
              v.put()
            oldvideos.remove(v)
            flag = 1
            break
      if flag != 1:
        # logging.info('new video:%r' % video)
        if video[1] == 'video' or video[1] == 'sound':
          keyname = MukioTools.rndvid(4)
          fileurl = video[2]
          vid = ''
          # logging.info('new video type video or sound:%r' % video[1])
        else:
          keyname = 'vid'+video[2]
          fileurl = ''
          vid = video[2]
          # logging.info('new video type not video or sound:%r' % video[1])
        # logging.info('hello')
        # logging.info('%r %r %r %r %r' % (keyname,video[1],vid,fileurl,video[0]))
        try:
          newvideo = Video(key_name = keyname,
                           typ = video[1],
                           vid = vid,
                           fileurl = fileurl,
                           parttitle = video[0],
                           art = article.key())
          if not newvideo:
            logging.info('new video Objected failed:%r' % video[1])
          else:
            # logging.info('new video Objected success:%r' % video[1])
            newvideo.put()
        except:
          logging.info('插入视频失败 %r' % (video))
    for v in oldvideos:
      MukioTools.delete_video_by_key_name(v.keyname)

class AdminError(BaseRequestHandler):
  def get(self):
    pass
    
class AdminDelete(BaseRequestHandler):
  def get(self,articlekey=None):
    pass

def main():
  app = webapp.WSGIApplication([
        (r'/admin[/]?',AdminPage),
        (r'/admin/(\d*)[/]?',AdminPage),
        (r'/admin/edit/([a-zA-Z0-9]*)[/]?',AdminEdit),
        (r'/admin/delete/([a-zA-Z0-9]*)[/]?',AdminDelete),
        ('/admin/error.*',AdminError),
        (r'/admin.*',_404)
        ],debug=_DEBUG)
  run_wsgi_app(app)

if __name__ == '__main__':
  main()