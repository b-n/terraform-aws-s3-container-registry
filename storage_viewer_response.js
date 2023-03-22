// This is a hash map of S3 header values to map to the response header values
var HEADER_MAPPINGS = {
  'x-amz-meta-docker-etag': 'etag',
  'x-amz-meta-docker-distribution-api-version': 'docker-distribution-api-version',
}

// This function returns a curried function which edits `response`. The curried
// function should only accept an array of 2 values, however cloudfront
// functions are limited in to their usage of ES6+ features.
function mapHeadersToResponse(response) {
  return function(mapping) {
    var header = mapping[0];
    var newHeader = mapping[1];
    if (response.headers[header] && response.headers[header]['value']) {
      response.headers[newHeader] = { value: response.headers[header]['value'] }
    }
  }
}

function handler(event) {
  var response = event.response;

  // map the returned headers to other headers in the response object
  var headerMapper = mapHeadersToResponse(response);
  Object.entries(HEADER_MAPPINGS).forEach(headerMapper)

  return response;
}
