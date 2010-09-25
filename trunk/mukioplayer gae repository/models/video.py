from google.appengine.ext import db

class Video(db.Model):
  typ = db.StringProperty()
  vid = db.StringProperty()
