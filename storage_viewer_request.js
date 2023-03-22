var REGEX_ENDS_WITH_SLASH = /\/$/;
var REGEX_ENDS_WITH_DIGEST = /\/([A-Za-z0-9_+.-]+):([0-9a-fA-F]+)$/

function handler(event) {
  var request = event.request;

  // modify the request uri if it ends with a `/` to include reference the default root object
  var request_uri = request.uri;

  if (REGEX_ENDS_WITH_SLASH.test(request_uri)) {
    // URL ends with `/`, we can redirect to the default object directory
    var next_uri = request_uri.replace(REGEX_ENDS_WITH_SLASH, '\/index.html');
    console.log(`Rewriting request from '${request_uri}' to '${next_uri}'`);
    request.uri = next_uri;
  } else if (REGEX_ENDS_WITH_DIGEST.test(request_uri)) {
    // URL is looking for a sha256 blob which is stored in a child directory
    var next_uri = request_uri.replace(REGEX_ENDS_WITH_DIGEST, '\/blobs\/$1\/$2');
    console.log(`Rewriting request from '${request_uri}' to '${next_uri}'`);
    request.uri = next_uri;
  }

  return request;
}
