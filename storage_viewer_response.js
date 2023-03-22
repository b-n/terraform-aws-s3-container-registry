function handler(event) {
  var response = event.response;

  if (response.headers['x-amz-meta-docker-etag'] && response.headers['x-amz-meta-docker-etag']['value']) {
    response.headers['etag'] = {
      value: response.headers['x-amz-meta-docker-etag']['value']
    };
  }

  return response;
}
