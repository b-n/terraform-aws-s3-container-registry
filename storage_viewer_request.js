function handler(event) {
  var request = event.request;

  // modify the request uri if it ends with a `/` to include reference the default root object
  var request_uri = request.uri;
  var next_uri = request_uri.replace(/\/$/, '\/index.html');
  if (request.uri != next_uri) {
    console.log(`Rewriting request from '${request_uri}' to '${next_uri}'`);
    request.uri = next_uri;
  }

  return request;
}
