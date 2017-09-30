void test_find_urls_simple() {
	var urls = Utils.find_urls("https://en.m.wikipedia.org/wiki/Isle_of_Man via DuckDuckGo for Android");

	assert(urls != null);
	assert(urls.length == 1);

	assert(urls[0] == "https://en.m.wikipedia.org/wiki/Isle_of_Man");
}

void test_find_urls_extract() {
	var urls = Utils.find_urls("Foo bar baz?\n\nhttp://foo.bar.com/123/345/abcd\n\nShared from my Google cards");

	assert(urls != null);
	assert(urls.length == 1);

	assert(urls[0] == "http://foo.bar.com/123/345/abcd");
}

void test_find_urls_many() {
	var urls = Utils.find_urls("https://foo.bar.com http://google.biz http://www.funny.io");

	assert(urls != null);
	assert(urls.length == 3);

	assert(urls[0] == "https://foo.bar.com");
	assert(urls[1] == "http://google.biz");
	assert(urls[2] == "http://www.funny.io");
}

void test_find_urls_none() {
	var urls = Utils.find_urls("baz bar \nbar.com foo ");

	assert(urls != null);
	assert(urls.length == 0);
}


public static void main(string[] args) {
	Test.init(ref args);

	Test.add_func("/mconn-utils/find-urls/simple", test_find_urls_simple);
	Test.add_func("/mconn-utils/find-urls/extract", test_find_urls_extract);
	Test.add_func("/mconn-utils/find-urls/many", test_find_urls_many);
	Test.add_func("/mconn-utils/find-urls/none", test_find_urls_none);
	Test.run();
}