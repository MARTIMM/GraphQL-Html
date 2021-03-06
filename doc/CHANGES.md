## CHANGELOG

See [semantic versioning](http://semver.org/). Please note point 4. on
that page: *Major version zero (0.y.z) is for initial development. Anything may
change at any time. The public API should not be considered stable.*

* 0.7.0
  * query links and link lists with r without images
  * search with user provided xpath. If search returns XML::Elements /text() is automatically added and text extracted.
  * read files from local disk using file:// protocol
  * added base field
* 0.6.0
  * query a list of images
  * added rest of attributes in an other field of Image
* 0.5.0
  * caching xpath in memory with a maximum of 10 objects
  * caching query documents in memory
* 0.4.0 query an image
* 0.3.0 caching a web page to a local file with sha1 encoded uri as its name
* 0.2.0 query a title
* 0.1.0 Setup
