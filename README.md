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
* `debian`: *Optional* Debian repo configuration. See the example below for keys.

## Example Configuration

### Resource type

``` yaml
- name: bintray
  type: docker-image
  source:
    repository: camelpunch/bintray-resource
    tag: v0.2 # optional, but shields you from breaking API changes
```

### Resource

``` yaml
- name: release
  type: bintray
  source:
    username: USERNAME
    api_key: API-KEY
    subject: myorg
    repo: myrepo
    package: some-package
```

### Plan

``` yaml
- put: release
  params:
    file: some-output/*/mypackage-*.ez
    version_regexp: some-output/(.*)/.*
    publish: true
    list_in_downloads: true
    licenses: ["Mozilla-1.1"]
    vcs_url: https://github.com/myorg/my-product
    debian: # you obviously wouldn't include this for non-debian packages
      distribution:
        - wheezy
        - jessie
        - stretch
      component:
        - main
        - contrib
      architecture:
        - i386
        - amd64
```

The above plan will cause three requests to take place:

1. POST to https://bintray.com/api/v1/packages/myorg/myrepo with JSON body. This creates the package.
2. PUT to https://bintray.com/api/v1/content/myorg/myrepo/mypackage-globbed-stuff.ez;publish=1;deb_distribution=wheezy,jessie,stretch;deb_component=main,contrib;deb_architecture=i386,amd64 with the file content.
3. PUT to https://bintray.com/api/v1/file_metadata/myorg/myrepo/mypackage-globbed-stuff.ez with

 ```json
{ "list_in_downloads": true }
```

If Bintray responds with `409 Conflict` for any of the requests (i.e. resource already exists), future requests continue as if nothing happened. Any other `4xx` / `5xx` response raises an exception, visible in Concourse logs.
