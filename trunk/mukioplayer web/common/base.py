import os

from google.appengine.ext import webapp
from google.appengine.ext.webapp import template
from google.appengine.api import users

from common.tools import MukioTools

_DEBUG = True

class BaseRequestHandler(webapp.RequestHandler):

  def render(self, template_name, template_values={}):

    user = users.get_current_user()

    if user:
      log_in_out_url = users.create_logout_url(self.request.uri)
    else:
      log_in_out_url = users.create_login_url(self.request.path)

    values = {'user': user,'items':MukioTools.namelist, 'log_in_out_url': log_in_out_url, 'admin':users.is_current_user_admin()}
    values.update(template_values)

    directory = os.path.dirname(__file__)
    path = os.path.join(directory, '..', 'templates', template_name)

    self.response.out.write(template.render(path, values, debug=_DEBUG))
    
class _404(BaseRequestHandler):
  def get(self):
    self.render('404.html')
