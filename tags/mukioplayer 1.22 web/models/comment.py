from google.appengine.api import users
from google.appengine.ext import db
from video import Video

class Comment(db.Model):
  author = db.UserProperty()
  text = db.StringProperty(required=True,multiline=True)
  postdate = db.DateTimeProperty(auto_now_add=True)
  stime = db.FloatProperty(required=True)
  mode = db.IntegerProperty(default=1)
  fontsize = db.IntegerProperty(default=25)
  color = db.IntegerProperty(default=0xffffff)
  cid = db.ReferenceProperty(Video)

