function FindProxyForURL(url,host)
{
	url=url.toLowerCase();
	host=host.toLowerCase();

	if(dnsDomainIs(host,"acfun.cn") || dnsDomainIs(host,"220.170.79.105"))
	{

		if(url.search(/newflvplayer\/player/) != -1)
		{
			return "proxy 127.0.0.1:80";
		}
	}
	else if(dnsDomainIs(host,"betoo.cn"))
	{

		if(url.search(/PAD\.swf/i) != -1)
		{
			return "proxy 127.0.0.1:80";
		}
	}
	return "direct";
}
