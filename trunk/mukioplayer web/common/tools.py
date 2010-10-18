# coding=utf-8
import re
import random
from math import floor
from datetime import datetime

from google.appengine.api import users

from models.article import Article
from models.video import Video
from models.chat import Chat
from models.comment import Comment
from models.cblock import CBlock

#需求登录修饰器
def loginRequired(func):
  def wrapper(self, *args, **kw):
    user = users.get_current_user()
    if not user:
      self.redirect(users.create_login_url(self.request.uri))
    else:
      func(self, *args, **kw)
  return wrapper

#一些工具
class MukioTools():
  namelist = [u'动画',u'音乐',u'游戏',u'娱乐',u'番影']
  @staticmethod
  def rndvid(n):
    return ''.join(random.sample(list('acbdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'),n))+''.join(random.sample(list('0123456789'),9))

  @staticmethod
  def tagname(n):
    return MukioTools.namelist[n]

  @staticmethod
  def delete(lst):
    for i in lst:
      i.delete()

  @staticmethod
  def delete_video_by_key_name(keyname):
    v = Video.get_by_key_name(keyname)
    if v:
      comments = v.comment_set
      MukioTools.delete(comments)
      cblocks = v.cblock_set
      MukioTools.delete(cblocks)# 新,删永久xml

      v.delete()

  @staticmethod
  def delete_comment_by_video_key_name(keyname):
    v = Video.get_by_key_name(keyname)
    if v:
      comments = v.comment_set
      MukioTools.delete(comments)

  @staticmethod
  def delete_permanent_comment_by_video_key_name(keyname):
    v = Video.get_by_key_name(keyname)
    if v:
      cblocks = v.cblock_set
      MukioTools.delete(cblocks)

  @staticmethod
  def delete_comment_by_video_key_name_without_author(keyname):
    v = Video.get_by_key_name(keyname)
    user = users.get_current_user()
    if v and user:
      comments = v.comment_set
      for c in comments:
        if c.author != user:
          c.delete()

  @staticmethod
  def delete_comment_by_id(id):
    c = Comment.get_by_id(id)
    if c:
      c.delete()

  @staticmethod
  def delete_article_by_key_name(keyname):
    a = Article.get_by_key_name(keyname)
    if a:
      videos = a.video_set
      for v in videos:
        MukioTools.delete_video_by_key_name(v.key().name())

      MukioTools.delete_chat_by_artkey_name(keyname)
      a.delete()

  @staticmethod
  def delete_chat_by_artkey_name(keyname):
    a = Article.get_by_key_name(keyname)
    if a:
      chats = a.chat_set
      for c in chats:
        MukioTools.delete_chat(c)

  @staticmethod
  def delete_chat(chat):
    chatchildren = chat.chat_set
    if chatchildren.count():
      for c in chatchildren:
        MukioTools.delete_chat(c)

    chat.delete()

  @staticmethod
  def dt_from_str(s):
    pt = re.compile(r'(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)\.(\d+)')
    tp = pt.findall(s)[0]
    ip = map(int,tp)
    return datetime(ip[0],ip[1],ip[2],ip[3],ip[4],ip[5],ip[6])

class Pager():
  ''' 1..n '''
  def __init__(self,current,perpage,linkdistance,totle,linktemplate='/admin/%(n)d',labeltemplate='[%(n)d]',alttemplate='第%(n)d页'):
    self.current = current
    self.perpage = perpage
    self.distance = linkdistance
    self.totle = totle
    self.linktemplate = linktemplate
    self.labeltemplate = labeltemplate
    self.alttemplate = alttemplate
  
    self.totlepage = int(floor((self.totle + self.perpage - 1) / self.perpage))
    if self.current > self.totlepage or self.current < 1:
      self.current = 1
      
    if self.distance >= self.current:
      self.prelinknumber = range(1,self.current);
    else:
      self.prelinknumber = range(self.current - self.distance,self.current)
    if self.distance > self.totlepage - self.current:
      self.nxtlinknumber = range(self.current + 1,self.totlepage + 1)
    else:
      self.nxtlinknumber = range(self.current + 1,self.current + self.distance + 1)
    
    # 当一翼小于distance时,扩展另一翼的长度
    if len(self.prelinknumber) < self.distance:
      n = self.distance - len(self.prelinknumber)
      while n > 0 and self.current + len(self.nxtlinknumber) < self.totlepage:
        self.nxtlinknumber.append(self.current + len(self.nxtlinknumber) + 1)
        n -= 1
    elif len(self.nxtlinknumber) < self.distance:
      n = self.distance - len(self.nxtlinknumber)
      while n > 0 and self.prelinknumber[0] - 1 > 0:
        self.prelinknumber.insert(0,self.prelinknumber[0] - 1)
        n -= 1
    
    self.frm = (self.current - 1) * self.perpage
    self.to = self.frm + self.perpage
    if self.to > self.totle:
      self.to = self.totle
    self.len = self.to - self.frm
    self.links = self.firstlink() + self.pre() + self.prelink() + self.currentlink() + self.nxtlink() + self.nxt() + self.lastlink()
    
  def firstlink(self):
    return self.renderlink(1,'首页')
    
  def lastlink(self):
    return self.renderlink(self.totlepage,'尾页')
  
  def renderlink(self,num,labeltemplate,alttemplate = None):
    if alttemplate == None: 
      alttemplate = self.alttemplate
    if num == self.current:
      return (labeltemplate % {'n':num})
    else:
      return '<a href="' + (self.linktemplate % {'n':num}) + '" title="' + (alttemplate % {'n':num}) + '">' + (labeltemplate % {'n':num}) + '</a>'
  
  def renderlistlink(self,lst):
    ret = ''
    for i in lst:
      ret += self.renderlink(i,self.labeltemplate)
    return ret
    
  def pre(self):
    if self.current == 1:
      return '前一页'
    else:
      return self.renderlink(self.current - 1,'前一页')
    
  def nxt(self):
    if self.current == self.totlepage:
      return '后一页'
    else:
      return self.renderlink(self.current + 1,'后一页')
      
  def currentlink(self):
    return self.renderlink(self.current,'%(n)d')
    
  def prelink(self):
    return self.renderlistlink(self.prelinknumber)
    
  def nxtlink(self):
    return self.renderlistlink(self.nxtlinknumber)
  
