#! /usr/bin/env python
# coding=utf-8
import sys
import BaseHTTPServer
import urllib
import urllib2

class LocalProxyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_CONNECT(self):
        self.wfile.write('HTTP/1.1 200 OK\r\n')
        self.wfile.write('\r\n')

        self.connection.close()

    def do_METHOD(self):

        print self.command,self.path
        print ''

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

    httpd = BaseHTTPServer.HTTPServer(('',80),LocalProxyHandler)
    httpd.serve_forever()
