import Default from './autocomplete/default'
import Resource from './autocomplete/resource'
import LinkedData from './autocomplete/linked_data'

export default class Autocomplete {
  /**
   * Setup for the autocomplete field.
   * @param {jQuery} element - The input field to add autocompete to
   * @param {string} fieldName - The name of the field (e.g. 'based_near')
   * @param {string} url - The url for the autocompete search endpoint
   */
  setup (element, fieldName, url) {
    if(element.data('autocomplete-type') && element.data('autocomplete-type').length > 0) {
      this.byDataAttribute(element, url)
    } else {
      this.byFieldName(element, fieldName, url)
    }
  }

  byDataAttribute(element, url) {
    let type = element.data('autocomplete-type')
    let exclude = element.data('exclude-work')
    if(type === 'resource' && exclude.length > 0) {
      new Resource(
        element,
        url,
        { excluding: exclude }
      )
    } else if(type === 'resource' ) {
      new Resource(
        element,
        url)
    } else if(type === 'linked') {
      new LinkedData(element, url)
    } else {
      new Default(element, url)
    }
  }

  byFieldName(element, fieldName, url) {
    switch (fieldName) {
      case 'work':
        new Resource(
          element,
          url,
          { excluding: element.data('exclude-work') }
        )
        break
      case 'collection':
        new Resource(
          element,
          url)
        break
      case 'based_near':
        new LinkedData(element, url)
        break
      default:
        new Default(element, url)
        break
    }
  }

}
