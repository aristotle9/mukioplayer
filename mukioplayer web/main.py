# coding=utf-8
###############
# 作者:aristotle9
# 程序主页:http://code.google.com/p/mukioplayer/
# 时间:2010年4月12日
# 最后更新:2010年9月27日
###############

import re
import urllib
import urllib2

from xml.sax.saxutils import escape
from datetime import timedelta
from datetime import datetime

from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.ext.webapp import template
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.api import users

from models.article import Article
from models.video import Video
from models.chat import Chat
from models.comment import Comment
from models.cblock import CBlock

from common.base import BaseRequestHandler,_404
from common.tools import loginRequired,MukioTools

_DEBUG = True
PAGESIZE = 14

#以下正文

#主题发布页面
class ArtPost(BaseRequestHandler):

  @loginRequired
  def post(self):
    title = unicode(self.request.get('title')).strip()
    abs = unicode(self.request.get('abs')).strip()
    tags = unicode(self.request.get('tags')).strip()
    classify = int(self.request.get('classify'))
    usr = users.get_current_user()
    if title and abs and usr:
      art = Article(key_name=MukioTools.rndvid(5),
                    author=usr,
                    title=title,
                    abs=abs,
                    classify=classify,
                    tags=tags.split()
                    )
      if art:
        art.put()

    self.redirect('/addvideo/' + art.key().name() +'/')

  @loginRequired
  def get(self):
    self.render('post.html',{'title':u'发布新主题'})

#主目录页
class ArtIndex(BaseRequestHandler):
  def get(self, bookmark = ''):
    '''Simple paging'''
    next = None
    prev = None
    if bookmark:
      bookmark = MukioTools.dt_from_str(urllib.unquote(urllib.unquote(bookmark)))
      #self.response.headers['Referer'] = bookmark
      arts = Article.all().order('-postdate').filter('postdate <=',bookmark).fetch(PAGESIZE + 1)
    else:
      arts = Article.all().order('-postdate').fetch(PAGESIZE+1)

    if len(arts) == PAGESIZE + 1:
      next = arts[-1].postdate
      arts = arts[:PAGESIZE]

    ars = []
    for a in arts:
      a.keyname = a.key().name()
      a.postdate += timedelta(hours=+8)
      a.tagname = MukioTools.tagname(a.classify)
      ars.append(a)

    if bookmark:
      arts = Article.all().order('postdate').filter('postdate >=',bookmark).fetch(PAGESIZE + 1)
      if len(arts) == PAGESIZE + 1:
        prev = arts[-1].postdate

    tmpvars = {'arts':ars,'next':next,'prev':prev}
    self.render('articles.html',tmpvars)

#分类目录页
class ClassifyIndex(BaseRequestHandler):
  def get(self, cls, bookmark = ''):

    cls = int(cls)
    if cls not in range(len(MukioTools.namelist)):
      self.error(404)
      return
    '''Simple paging'''
    next = None
    prev = None
    if bookmark:
      bookmark = MukioTools.dt_from_str(urllib.unquote(urllib.unquote(bookmark)))
      arts = Article.all().order('-postdate').filter('classify =',cls).filter('postdate <=',bookmark).fetch(PAGESIZE + 1)
    else:
      arts = Article.all().order('-postdate').filter('classify =',cls).fetch(PAGESIZE+1)

    if len(arts) == PAGESIZE + 1:
      next = arts[-1].postdate
      arts = arts[:PAGESIZE]

    ars = []
    for a in arts:
      a.keyname = a.key().name()
      a.postdate += timedelta(hours=+8)
      a.tagname = MukioTools.tagname(a.classify)
      ars.append(a)

    if bookmark:
      arts = Article.all().order('postdate').filter('classify =',cls).filter('postdate >=',bookmark).fetch(PAGESIZE + 1)
      if len(arts) == PAGESIZE + 1:
        prev = arts[-1].postdate

    tmpvars = {'arts':ars,'next':next,'prev':prev,'title':u'分类:' + MukioTools.namelist[cls],'iscls':True,'cls':cls}
    self.render('articles.html',tmpvars)

#个人作品列表
class UserIndex(BaseRequestHandler):
  def get(self,email,bookmark = ''):

    email = urllib.unquote(urllib.unquote(email))
    usr = users.User(unicode(email).strip())

    next = None
    prev = None
    if bookmark:
      bookmark = MukioTools.dt_from_str(urllib.unquote(urllib.unquote(bookmark)))
      arts = Article.all().order('-postdate').filter('author = ',usr).filter('postdate <=',bookmark).fetch(PAGESIZE + 1)
    else:
      arts = Article.all().order('-postdate').filter('author = ',usr).fetch(PAGESIZE+1)

    if len(arts) == PAGESIZE + 1:
      next = arts[-1].postdate
      arts = arts[:PAGESIZE]

    ars = []
    for a in arts:
      a.keyname = a.key().name()
      a.postdate += timedelta(hours=+8)
      a.tagname = MukioTools.tagname(a.classify)
      ars.append(a)

    if bookmark:
      arts = Article.all().order('postdate').filter('author = ',usr).filter('postdate >=',bookmark).fetch(PAGESIZE + 1)
      if len(arts) == PAGESIZE + 1:
        prev = arts[-1].postdate


    self.render('articles.html',{'arts':ars,'author':usr,'next':next,'prev':prev,'title':usr.nickname() + unicode('的上传列表','utf-8'),'edit':usr == users.get_current_user()})

#视频发布页
class VideoPost(BaseRequestHandler):

  @loginRequired
  def get(self,aid):
    #arts = Article.all()
    #arts.filter('__key__ =',db.Key(aid))
    art = Article.get_by_key_name(aid.strip())#arts.get()
    usr = users.get_current_user()
    if (not art) or (art.author != usr):
      self.redirect('/')

    if art:
      art.keyname = art.key().name()
      videos = art.video_set
      videos.order('postdate')
      vds = []
      for v in videos:
        v.keyname = v.key().name()
        v.cbk = v.cblock_set.count()
        vds.append(v)
      tmpvars = {'art':art,
                 'title':unicode('添加视频 - ','utf-8') + art.title,
                 'vds':vds}
      self.render('addvideo.html',tmpvars)
    else:
      self.redirect('/')

  @loginRequired
  def post(self):
    parttitle = unicode(self.request.get('parttitle')).strip()
    #vid = unicode(self.request.get('vid')).strip()
    fileurl = unicode(self.request.get('fileurl')).strip()
    typ = unicode(self.request.get('typ')).strip()
    artkeystr = unicode(self.request.get('articleId')).strip()
    artkey = db.Key(artkeystr)
    if not artkey:
      self.redirect('/')

    art = Article.get(artkey)
    usr = users.get_current_user()
    if art.author == usr:
      self.redirect('/')

    if typ == 'bokecc':

      reg = re.compile(r'http://.*vid=([^&]+)',re.I)
      res = reg.findall(fileurl)

      if len(res) == 1:
        vid = res[0]
      else:
        vid = fileurl

      fileurl = ''
      keyname = 'vid' + vid

    elif typ == 'sina' or typ == 'youku' or typ == '6room' or typ == 'qq':
      vid = fileurl
      fileurl = ''
      keyname = 'vid' + vid

    elif typ == 'video':
      vid = ''
      keyname = MukioTools.rndvid(4)

    else:
      self.error(404)
      
    '''typ = 'sina'
    if not vid:
      typ = 'video'
      if not fileurl:
        typ = 'none'

    if typ == 'none':
      self.redirect('/')
    else:
      if typ == 'sina':
        keyname = 'vid' + vid
      else:
        reg = re.compile(r'vid=([^&]+)',re.I)
        res = reg.findall(fileurl)
        if len(res) == 1:
          typ = 'bokecc'
          vid = res[0]
          keyname = 'vid' + res[0]
        else:
          keyname = MukioTools.rndvid(4)'''

    video = Video(key_name=keyname,
                  typ=typ,
                  vid=vid,
                  fileurl=fileurl,
                  parttitle=parttitle,
                  art=artkey
                  )
    if video:
      video.put()
      self.redirect('/addvideo/' + artkey.name() + '/')
    else:
      self.redirect('/')
#观看视频页
class VideoIndex(BaseRequestHandler):
  def get(self,aid,prt):
    #artkey = aid.strip()#db.Key(str(aid).strip())
    #arts = Article.all()
    #arts.filter('__key__=',artkey)
    if prt == '':
      prt = 0
    else:
      prt = int(prt)

    art = Article.get_by_key_name(unicode(aid).strip())#arts.get()
    if not art:
      self.redirect('/articles.php')

    else:
      art.clickstatis += 1
      art.put()
      art.keyname = art.key().name()
      art.tagname = MukioTools.tagname(art.classify)
      art.postdate += timedelta(hours=+8)
      
      videos = art.video_set
      if prt > videos.count():
        prt = 0

      videos.order('postdate')

      vdlinks = []
      if videos.count() > 1:
        for i in range(videos.count()):
          vdlinks.append({'n':i,'ptitle':videos[i].parttitle,'selected':i == prt})

      vds = videos.fetch(1,prt)
      vd = None
      if len(vds):
        vd = vds[0]
        vd.keyname = vd.key().name()
      tmpvars = {
                'art':art,
                'video':vd,
                'title':art.title,
                'links':vdlinks,
                'part':prt,
                'host':self.request.headers['host']
                }
      self.render('videos.html',tmpvars)
#弹幕的发送与接收
class CommentIndex(BaseRequestHandler):
  def get(self,cid,block=''):
    video = Video.get_by_key_name('vid' + cid)
    if not video:
      video = Video.get_by_key_name(cid)

    if block == 'permanent':#新,双重字幕中的永久字幕,可以通过导入空的xml来覆盖
      block = video.cblock_set.get()
      self.render('pcmt.xml',{'cblock':block})
    else:
      comments = []
      if video:
        cmts = video.comment_set
        #cmts.order('parttitle')
        for c in cmts:
          c.keyid = c.key().id()
          c.postdate += timedelta(hours=+8)
          comments.append(c)

      tmpvars = {'comments':comments}
      self.render('comment.xml',tmpvars)

#  @loginRequired
  def post(self):
    print 'Content-Type: text/plain'
    print ''

    video = Video.get_by_key_name('vid' + self.request.get('playerID'))
    if not video:
      video = Video.get_by_key_name(self.request.get('playerID'))
    author = users.get_current_user()
    if video:
      text = unicode(self.request.get('message')).strip()
      stime = float(self.request.get('playTime'))
      mode = int(self.request.get('mode'))
      fontsize = int(self.request.get('fontsize'))
      color = int(self.request.get('color'))

      cmt = Comment(author=author,
                    text=text,
                    stime=stime,
                    mode=mode,
                    fontsize=fontsize,
                    color=color,
                    cid=video)
      if cmt:
        cmt.put()
        print 'OK'
      else:
        print 'Failed'
    else:
      print 'Failed'

#删除句柄
class DeleteHandler(BaseRequestHandler):
  def get(self,action,id_key):
    self.user = users.get_current_user()
    if action == 'video':
      self.delete_video(id_key)
    elif action == 'article':
      self.delete_article(id_key)
    elif action == 'comment':
      self.delete_all_comment(id_key)
    elif action == 'usercomment':
      self.delete_user_comment(id_key)
    elif action == 'permanentcomment':
      self.delete_permanent_comment(id_key)
    
    if self.request.headers['Referer']:
      self.redirect(self.request.headers['Referer'])
    else:
      self.redirect('/')

  def delete_permanent_comment(self, key_name):
    video = Video.get_by_key_name(key_name)
    if video:
      if video.art.author == self.user:
        MukioTools.delete_permanent_comment_by_video_key_name(key_name)

  def delete_user_comment(self, key_name):
    video = Video.get_by_key_name(key_name)
    if video:
      if video.art.author == self.user:
        MukioTools.delete_comment_by_video_key_name_without_author(key_name)

  def delete_all_comment(self, key_name):
    video = Video.get_by_key_name(key_name)
    if video:
      if video.art.author == self.user:
        MukioTools.delete_comment_by_video_key_name(key_name)
  
  def delete_video(self, key_name):
    video = Video.get_by_key_name(key_name)
    if video:
      if video.art.author == self.user:
        MukioTools.delete_video_by_key_name(key_name)

  def delete_article(self, key_name):
    article = Article.get_by_key_name(key_name)
    if article:
      if article.author == self.user:
        MukioTools.delete_article_by_key_name(key_name)
#视频下跟帖
class ChatHandler(BaseRequestHandler):

  @loginRequired
  def post(self):

    author = users.get_current_user()
    author_ip = self.request.remote_addr
    artkeystr = self.request.get('articleId')
    artkey = db.Key(artkeystr.strip())
    text = self.request.get('text').strip()
    parentidstr = self.request.get('parentId')

    if parentidstr.strip() == '':
      parent_chat = None
      art = artkey
    else:
      parent_chat = Chat.get_by_id(int(parentidstr))
      art = None

    chat = Chat(author=author,
                author_ip=author_ip,
                art=art,
                text=text,
                parent_chat=parent_chat)

    if chat:
      chat.put()
      self.get(artkey.name())
    else:
      print 'Content-Type: text/plain'
      print ''
      print 'Failed'

  def get(self,artkeynamestr):
    art = Article.get_by_key_name(artkeynamestr.strip())
    if art:
      chats = art.chat_set
      chats.order('postdate')
      chatstr = ''
      for i in range(chats.count()):
        chatstr += self.renderchat(chats[i],str(i))

      self.render('chats.html',{'chatstr':chatstr,'art':art})

    else:
      self.error(404)

  def renderchat(self,chat,n):

    res = '<div class=\'chatitem' + str((len(n) - 1) / 2 % 2) + '\'>'
    res += '<div class=\'caption\' id=\'chatid-'+ str(chat.key().id()) +';\'><span class=\'floor-num\'>'
    res += unicode(n + '楼:','utf-8')
    res += '</span><span class=\'author\'>'
    res += chat.author.nickname()
    res += '</span><span class=\'postdate\'>'
    res += (chat.postdate + timedelta(hours=+8)).strftime("%Y-%m-%d %H:%M:%S")#.isoformat(' ')
    res += '</span><a onclick=\'document.postchat.parentId.value = '+ str(chat.key().id()) +unicode(';return false;\'> 回复</a></div><div class=\'chatcontent\'>','utf-8')
    res += escape(chat.text).replace('\n','<br />\n')
    chatchildren = chat.chat_set
    chatchildren.order('postdate')
    for i in range(chatchildren.count()):
      res += self.renderchat(chatchildren[i],n + '-' + str(i))
    
    res += '</div></div>'
    return res

#外链URL美化
class ExternalLinkHandler(BaseRequestHandler):
  def get(self,aid,prt):
    if prt == '':
      prt = 0
    else:
      prt = int(prt)

    art = Article.get_by_key_name(unicode(aid).strip())#arts.get()
    if not art:
      self.error(404)

    else:
      art.clickstatis += 1
      art.put()
      
      videos = art.video_set
      if prt > videos.count():
        prt = 0

      videos.order('postdate')


      vds = videos.fetch(1,prt)
      vd = None
      flashvars = '/mukioplayer.swf?id='
      if len(vds):
        vd = vds[0]
        if vd.vid:
          flashvars += vd.vid
          if vd.typ == 'bokecc' or vd.typ == '6room' or vd.typ == 'youku' or vd.typ == 'qq':
            flashvars += '&type=' + vd.typ;
        else:
          flashvars += vd.key().name()
          flashvars += '&file=' + vd.fileurl

        self.redirect(flashvars)
      else:
        self.error(404)

#导入外部弹幕xml,永久xml
class AddBlockHandler(BaseRequestHandler):
  @loginRequired
  def get(self,cid):
    video = Video.get_by_key_name(cid)
    if not video:
      self.error(404)
    else:
      self.render('addblock.html',{'video':video,'title':'Add/Update XML File for Video: ' + video.key().name()})

  @loginRequired
  def post(self):
    user = users.get_current_user()
    vkeystr = unicode(self.request.get('videoId')).strip()
    vkey = db.Key(vkeystr)
    if not vkey:
      self.error(404)
    else:
      video = Video.get(vkey)
      path = unicode(self.request.get('path')).strip()
      if path == '' and self.request.POST.get('localfile') == '':
        self.redirect('/addvideo/' + video.art.key().name() + '/')
      else:
        if video.cblock_set.count():
          MukioTools.delete(video.cblock_set)#删除已经存在的外部XML
        if user != video.art.author:
          self.error(404)#只有本人才能进行该操作

        data = self.getfile()
        
        if data:
          cbk = CBlock(link=path,
                       data=unicode(data,'utf-8'),
                       cid=video)
          if cbk:
            cbk.put()
            self.redirect('/addvideo/' + video.art.key().name() + '/')
        else:
          self.error(404)
          
  def getfile(self):
    path = unicode(self.request.get('path')).strip()
    if path != '':
      rq = urllib2.Request(path)
      data = ''
      try:
        resp = urllib2.urlopen(rq)
        data = resp.read()
      except urllib2.URLError, e:
        pass
      if data != '':
        return data
    elif self.request.POST.get('localfile') != '':
      data = self.request.get('localfile')
      # data = db.Text(data.decode('utf-8'))
      return data
    return ''

#6room代理页面,直接连接的话会被拒绝
class SixRoom(BaseRequestHandler):
  def get(self):
    self.error(404)

  def post(self,vid):
    msg = self.request.get('echo')#say hello MUST
    if (not msg) or msg != 'hello':
      self.error(404)

    headers = self.request.headers;
    headers.update({'User-Agent':'','Referer':'http://6.cn/'})#Setting User-Agent None is important
    req = urllib2.Request(self.getPath(vid), None, headers)
    ptn = re.compile(r'<file_xml>(.+)</file_xml>',re.M)
    try:
      resp = urllib2.urlopen(req)
      #self.wfile.write('HTTP/1.1 200 OK\r\n')
      dat = resp.read()
      self.response.out.write(ptn.findall(dat)[0])

    except urllib2.HTTPError, e:
      self.error(304)
    except urllib2.URLError, e:
      self.error(404)

  def getPath(self,vid):
    return 'http://6.cn/v72.php?vid=' + vid



app = webapp.WSGIApplication([('/post.php',ArtPost),
                              ('/',ArtIndex),
                              (r'/page/(.*)/[#]?',ArtIndex),
                              ('/articles.php',ArtIndex),
                              (r'/item/(.*)/(.*)/[#]?',ClassifyIndex),
                              (r'/item/(.*)/',ClassifyIndex),
                              (r'/addvideo/(.*)/',VideoPost),
                              ('/postvideo.php',VideoPost),
                              (r'/videos/(.*)/(.*)',VideoIndex),
                              (r'/comment/(.*)/',CommentIndex),
                              (r'/pcomment/(.*)/(.*)/',CommentIndex),
                              (r'/newflvplayer/xmldata/(.*)/comment_on.xml',CommentIndex),#保留,不推荐
                              ('/newflvplayer/cnmd.aspx',CommentIndex),#保留,不推荐
                              ('/postcomment.php',CommentIndex),
                              (r'/userlist/(.*)/(.*)/[#]?',UserIndex),
                              (r'/userlist/(.*)/',UserIndex),
                              (r'/delete/(.*)/(.*)/',DeleteHandler),
                              (r'/chatlist/(.*)/',ChatHandler),
                              ('/postchat/',ChatHandler),
                              (r'/links/(.*)/(.*)/mukioplayer\.swf',ExternalLinkHandler),
                              (r'/addblock/(.*)/',AddBlockHandler),
                              ('/addblock',AddBlockHandler),
                              (r'/(.*)/sixroom/',SixRoom),
                              (r'.*',_404)
                              ],debug=_DEBUG)

if __name__ == '__main__':
  run_wsgi_app(app)