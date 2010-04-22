from google.appengine.api import users
from google.appengine.ext import db

class Article(db.Model):
  author = db.UserProperty(required=True)
  postdate = db.DateTimeProperty(auto_now_add=True)
  updatedate = db.DateTimeProperty(auto_now_add=True)
  title = db.StringProperty(required=True)
  abs = db.StringProperty(multiline=True)
  tags = db.StringListProperty(default=[])
  classify = db.IntegerProperty(required=True,choices=set([0,1,2,3,4])) 
  clickstatis = db.IntegerProperty(default=0)

