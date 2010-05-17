#! /usr/bin/env python
# coding=utf-8
import sys
import BaseHTTPServer
import urllib
import urllib2
#from SimpleHTTPServer import SimpleHTTPRequestHandler
#
#HandlerClass = SimpleHTTPRequestHandler
#ServerClass  = BaseHTTPServer.HTTPServer
#Protocol     = "HTTP/1.0"
#if sys.argv[1:]:
#    port = int(sys.argv[1])
#else:
#    port = 8000
#server_address = ('127.0.0.1', port)
#HandlerClass.protocol_version = Protocol
#httpd = ServerClass(server_address, HandlerClass)
#sa = httpd.socket.getsockname()
#print "Serving HTTP on", sa[0], "port", sa[1], "..."
#httpd.serve_forever() 
class LocalProxyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_CONNECT(self):
        self.wfile.write('HTTP/1.1 200 OK\r\n')
        self.wfile.write('\r\n')
        #self.wfile.write('Hello World!')
        self.connection.close()

    def do_METHOD(self):
#        self.wfile.write('HTTP/1.1 200 OK\r\n')
#        self.wfile.write('\r\n')
#        self.wfile.write('Hello World!\n')
#        self.wfile.write(self.server_version + '\n')
#        self.wfile.write(self.sys_version + '\n')
#        self.wfile.write(self.protocol_version + '\n')
#        self.wfile.write(self.path  + '\n')
#        self.wfile.write(urllib.urlencode(self.headers)  + '\n')
#        self.wfile.write('\n'.join(self.headers) + '\n')
        print self.command,self.path
        print ''
        #print(self.headers)
#        self.headers['Connection'] = 'close'
        '''req = urllib2.Request(self.path,None,self.headers)
        try:
          resp = urllib2.urlopen(req)
          self.wfile.write('HTTP/1.1 200 OK\r\n')
#          print(resp.headers)
          for header in resp.headers:
            self.send_header(header,resp.headers[header])

          self.end_headers()
          self.wfile.write(resp.read())
        except urllib2.HTTPError, e:
          print e
          self.send_error(304)
        except urllib2.URLError, e:
          print e'''
        f = open("mukioplayer-flex.swf","r+b")
        dat = f.read()
        f.close()
        self.wfile.write('HTTP/1.1 200 OK\r\n')
        self.send_header('Content-Length',len(dat))
        self.send_header('Cache-Control','max-age=1')
        self.send_header('Content-Type','application/x-shockwave-flash')
        self.end_headers()
        self.wfile.write(dat)
        self.connection.close()

    do_GET = do_METHOD
    do_HEAD = do_METHOD
    do_POST = do_METHOD


if __name__ == '__main__':
    #f = open("D:/My Softwares/flash/flex/jw/mukiuplayer1.126b Web/mukioplayer.swf","r+b")
    httpd = BaseHTTPServer.HTTPServer(('',80),LocalProxyHandler)
    httpd.serve_forever()
