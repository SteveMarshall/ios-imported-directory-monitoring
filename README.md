# iOS imported directory monitoring

This repository holds a minimal example project to demonstrate how to
monitor the file system for changes to [directories imported from
outside the current app's container][import-directories].

It shows two theoretically-valid approaches to observing changes to
directories:

- Using [`NSMetadataQuery`][nsmetadataquery], as per the [documentation
  for searching file metadata with `NSMetadataQuery`][querying-metadata].
  **This does not work.**
- Using an implementation of [`NSFilePresenter`][nsfilepresenter],
  whose documentation describes it as “The interface […] to inform an
  object […] about changes to that file”.

[import-directories]: https://developer.apple.com/documentation/uikit/view_controllers/providing_access_to_directories
[nsmetadataquery]: https://developer.apple.com/documentation/foundation/nsmetadataquery
[nsfilepresenter]: https://developer.apple.com/documentation/foundation/nsfilepresenter
[querying-metadata]: https://developers.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryingMetadata.html

## Running this code

To run this code, make sure to replace all instances of `Sample`
and `iCloud.com.stevemarshall.Sample` with references to an iCloud
bucket you own, and run it on a device or simulator that's logged in to
an appropriately-credentialed iCloud account.
