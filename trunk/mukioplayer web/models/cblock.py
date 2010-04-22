from google.appengine.ext import db
from video import Video

class CBlock(db.Model):
  data = db.TextProperty()
  link = db.StringProperty()
  postdate = db.DateTimeProperty(auto_now_add=True)
  cid = db.ReferenceProperty(Video)

