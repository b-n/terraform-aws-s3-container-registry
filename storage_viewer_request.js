var REGEX_REWRITE_ROUTES = [
  [/\/$/, '\/index.html'],
  [/\/manifests\/([A-Za-z0-9_+.-]+):([0-9a-fA-F]+)$/, '\/blobs\/$1\/$2'],
  [/\/blobs\/([A-Za-z0-9_+.-]+):([0-9a-fA-F]+)$/, '\/blobs\/$1\/$2'],
]

// Returns a rewriter which will take a rewrite rule, check if it applies to
// the current route, and if yes will rewrite it with the replaced value
function rewriteUri(request) {
  return function(rewrite_rule) {
    var regex = rewrite_rule[0];
    var replaceWith = rewrite_rule[1];

    if (regex.test(request.uri)) {
      var next_uri = request.uri.replace(regex, replaceWith);
      console.log(`Rewriting request from '${request.uri}' to '${next_uri}'`);
      request.uri = next_uri;
    }
  }
}

function handler(event) {
  var request = event.request;

  var rewriter = rewriteUri(request);
  REGEX_REWRITE_ROUTES.forEach(rewriter);

  return request;
}
