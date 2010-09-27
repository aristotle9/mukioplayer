from google.appengine.ext import db
from article import Article

class Video(db.Model):
  typ = db.StringProperty()
  postdate = db.DateTimeProperty(auto_now_add=True)
  parttitle = db.StringProperty()
  vid = db.StringProperty()
  fileurl = db.StringProperty()
  art = db.ReferenceProperty(Article)