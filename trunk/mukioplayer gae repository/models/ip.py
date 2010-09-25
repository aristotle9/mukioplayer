from google.appengine.ext import db

class Ip(db.Model):
  ip = db.StringProperty()
  lastpostdate = db.DateTimeProperty()
