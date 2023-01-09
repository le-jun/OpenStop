part of 'base_element.dart';

/// A wrapper class to modify the tags of [OSMElement]s without changing or exposing them.

class ProxyElement<T extends osmapi.OSMElement, G extends GeographicGeometry> extends ProcessedElement<T, G> {
  final ProcessedElement<T, G> _element;

  ProxyElement(this._element, {
    Map<String, String>? additionalTags,
  }) : additionalTags = additionalTags ?? {},
       super(_element._osmElement);

  /// Tags that should be added or overridden.

  final Map<String, String> additionalTags;

  /// Contains all original tags and those added by changes.

  @override
  late final CombinedMapView<String, String> tags = CombinedMapView([
    // on duplicates the first value will be returned
    // therefore move additionalTags to the start
    additionalTags, super.tags
  ]);


  /// Updates the underlying OSM element with the given tags and
  /// uploads it to the OSM server.
  ///
  /// The method primarily exists to prevent the exposal of the underlying original OSM element.
  ///
  /// Returns the [ProcessedElement] with all tags applied and updated version.
  ///
  /// This method may throw any upload/OSMAPI errors.
  /// In this case the changes to the underlying element are reverted.

  Future<ProcessedElement<T, G>> publish(OSMElementUploadAPI uploadAPI) async {
    // create tag copy for rollback
    final tagCopy = Map.of(_osmElement.tags);
    // apply all tags to underlying OSM element
    _osmElement.tags.addAll(additionalTags);
    try {
      // trigger upload
      await uploadAPI.updateOsmElement(this, _osmElement);
      // on success clear any added tags
      additionalTags.clear();
    }
    catch (e) {
      // revert applied changes on error
      _osmElement.tags..clear()..addAll(tagCopy);
      rethrow;
    }
    return _element;
  }

  // forward methods from processed elements

  @override
  G get geometry => _element.geometry;

  /// Any elements this element is a part of.
  /// The elements are unordered and do not contain duplicates.
  @override
  UnmodifiableSetView<ParentElement> get parents => _element.parents;

  /// Any elements this element consists of.
  /// The elements are unordered and do not contain duplicates.
  @override
  UnmodifiableSetView<ChildElement> get children => _element.children;

  @override
  void calcGeometry() => _element.calcGeometry();
}
