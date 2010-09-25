from google.appengine.ext import db
from video import Video

class Comment(db.Model):
  author_ip = db.StringProperty(required=True)
  text = db.StringProperty(required=True,multiline=True)
  postdate = db.DateTimeProperty()
  stime = db.FloatProperty(required=True)
  mode = db.IntegerProperty(default=1)
  fontsize = db.IntegerProperty(default=25)
  color = db.IntegerProperty(default=0xffffff)
  cid = db.ReferenceProperty(Video)

