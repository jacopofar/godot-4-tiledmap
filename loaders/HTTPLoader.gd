extends Node
# caching is very simple here
# for fancier approaches see: https://github.com/fenix-hub/gdcache

# here HTTPRequest is used, high level node over HTTPClient
# HTTPCLient is quite a mess to use, and in particular to troubleshoot
# see https://gist.github.com/bibby/9150165
# potentially is faster because it reuses the same connection to the host

var CACHE_SIZE = 60

var json_cache: Dictionary = {}
var image_cache: Dictionary = {}

func normalize_url(url: String):
	# ugly but necessary :(
	var url_parts = url.replace(" ", "%20").split("/")
	for i in range(url_parts.size()):
		if url_parts.size() <= i:
			# the size changes as we remove elements
			break
		if url_parts[i] == '..':
			url_parts.remove_at(i)
			url_parts.remove_at(i - 1)
	return "/".join(url_parts)


func load_json(url: String):
	url = normalize_url(url)
#	print("loading ", url)
	if json_cache.has(url):
#		print("cache hit for ", url)
		return [null, json_cache[url]]
#	print("cache miss, will load ", url)
#
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(url)
	if error != OK:
		push_error("An error occurred in the HTTP request: ", error)
	# will yield _result, _response_code, _headers, body
	var http_result = (await http_request.request_completed)
	if int(http_result[1] / 100) != 2:
		print("NON 200 HTTP: ", http_result[1], " ", url)
		return [str("Non-200 HTTP code ", http_result[1]), null]
	var body = http_result[3]
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	if json_cache.size() > CACHE_SIZE:
		# just clear for now
		json_cache = {}
	json_cache[url] = json.get_data()
#	print("loaded ", url)

	return [null, json.get_data()]

func load_image(url: String):
	url = normalize_url(url)
	if image_cache.has(url):
		return [null, image_cache[url]]


	var http_request = HTTPRequest.new()
	add_child(http_request)
	var error = http_request.request(url)
	if error != OK:
		push_error("An error occurred in the HTTP request: ", error)
	# will yield _result, _response_code, _headers, body
	var http_result = (await http_request.request_completed)
	if int(http_result[1] / 100) != 2:
		push_error("Non-200 HTTP code ", http_result[1], " with URL ", url)
	var body = http_result[3]
	var image = Image.new()
	# TODO handle non-PNG
	image.load_png_from_buffer(body)
	if image_cache.size() > CACHE_SIZE:
		# just clear for now
		image_cache = {}
	image_cache[url] = image
	return [null, image]
