# coding=utf-8
###############
# 作者:aristotle9
# 程序主页:http://code.google.com/p/mukioplayer/
# 时间:2010年5月3日
###############
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import template
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.api import memcache
from google.appengine.api import users

from models.video import Video
from models.ip import Ip
from models.comment import Comment
from models.cblock import CBlock

from datetime import timedelta,datetime

import random
import os,re
import urllib,urllib2
from xml.sax.saxutils import escape

_DEBUG = False
POSTINTERVAL = 10#10秒一发
DELAYMAX = 60#最大延迟允许秒
DELAYCHECK = False#开启延迟过滤

#需求登录修饰器
def loginRequired(func):
  def wrapper(self, *args, **kw):
    user = users.get_current_user()
    if not user:
      self.redirect(users.create_login_url(self.request.uri))
    else:
      func(self, *args, **kw)
  return wrapper

#以下正文
############################################
#基类
class BaseRequestHandler(webapp.RequestHandler):

  def render(self, template_name, template_values={}):

    user = users.get_current_user()

    if user:
      log_in_out_url = users.create_logout_url(self.request.uri)
    else:
      log_in_out_url = users.create_login_url(self.request.path)

    values = {'user': user, 'log_in_out_url': log_in_out_url}
    values.update(template_values)

    directory = os.path.dirname(__file__)
    path = os.path.join(directory, 'templates', template_name)

    self.response.out.write(template.render(path, values, debug=_DEBUG))

class CommentHandler(BaseRequestHandler):
  def get(self,typ,vid):
    video = Video.all().filter('typ =',typ).filter('vid =',vid).get()
    if not video:
      video = Video(typ = typ,
                    vid = vid)
      if video:
        video.put()
      else:
        self.error(404)

    cmts = memcache.get(str(video.key().id_or_name()))
    if not cmts:
      cmts = video.comment_set
      memcache.set(str(video.key().id_or_name()),cmts)

    tmpvars = {'comments':cmts}
    self.render('comment.xml',tmpvars)

  def post(self,typ,vid):
    now = datetime.now() + timedelta(hours=+8)
    #date check
    date = self.request.get('date')
    try:
      date = datetime.strptime(date,'%Y-%m-%d %H:%M:%S')
      postdelta = abs(now - date)
    except:#拒绝不合法的时间格式
      self.response.out.write('busy,code:1')
      return

    #self.response.out.write(str(abs(postdelta.seconds))+'\r\n')#不能给用户看到

    if DELAYCHECK and (postdelta.days != 0 or postdelta.seconds > DELAYMAX):#时间有效性检验,如果与服务器间隔大于60s,就为非法
      self.response.out.write('busy,code:2')
      return


    #post interval limitation
    ipstr = self.request.remote_addr
    ip = Ip.all().filter('ip =',ipstr).get()
    if ip:
      delta = now - ip.lastpostdate
      if delta.days == 0 and abs(delta.seconds) < POSTINTERVAL:
        self.response.out.write('busy,code:3')
        return
      else:
        ip.lastpostdate = now
        ip.put()
    else:
      ip = Ip(ip=ipstr,lastpostdate = now)
      ip.put()
        


    video = Video.all().filter('typ =',typ).filter('vid =',vid).get()
    if not video:
      video = Video(typ = typ,
                    vid = vid)
      if video:
        video.put()
      else:
        self.error(404)

    text = unicode(self.request.get('message')).strip()
    stime = float(self.request.get('playTime'))
    mode = int(self.request.get('mode'))
    fontsize = int(self.request.get('fontsize'))
    color = int(self.request.get('color'))

    cmt = Comment(author_ip=ipstr,
                  text=text,
                  stime=stime,
                  mode=mode,
                  fontsize=fontsize,
                  color=color,
                  cid=video,
                  postdate=(datetime.now() + timedelta(hours=+8))
                  )

    if cmt:
      cmt.put()
      memcache.delete(str(video.key().id_or_name()))
      self.response.out.write('OK')
    else:
      self.response.out.write('Failed')

app = webapp.WSGIApplication([(r'/([^/]*)/(.*)/post/',CommentHandler),
                              (r'/([^/]*)/(.*)/get/',CommentHandler)
                              ],debug=_DEBUG)

if __name__ == '__main__':
  run_wsgi_app(app)