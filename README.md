# Bintray Resource

Out-only resource for pushing OSS content to Bintray.

## Source Configuration

* `username`: *Required.* The Bintray username to upload with
* `api_key`: *Required.* The Bintray API key associated with the above user.
* `subject`: *Required.* The organisation to upload this package to.
* `repo`: *Required.* The repository to upload this package to.
* `package`: *Required.* The name of the package to create / upload to.

## Behaviour

### `out`: Upload content to a package. Create the package if it doesn't exist.

#### Parameters

* `file`: *Required.* Path to the file to upload, provided by the output of a task.
  If multiple files are matched by the glob, an error is raised. The file which
  matches will be uploaded as content to the version as found in the `version_regexp`
  parameter.
* `version_regexp`: *Required.* The pattern to match filenames against on disk. The first
  grouped match is used to extract the version.
* `publish`: *Optional.* Whether to mark the uploaded content as published.
* `list_in_downloads`: *Optional.* Whether to list the uploaded file in the downloads list.
* `licenses`: *Required.* A list of licenses which must match those available on Bintray.
* `vcs_url`: *Required.* The URI for the package's public version control.
