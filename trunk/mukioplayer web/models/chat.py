from google.appengine.ext import db
from article import Article

class Chat(db.Model):
  author = db.UserProperty(required=True)
  author_ip = db.StringProperty(required=True)
  art = db.ReferenceProperty(Article)
  postdate = db.DateTimeProperty(auto_now_add=True)
  text = db.StringProperty(required=True,multiline=True)
  parent_chat = db.SelfReferenceProperty()
