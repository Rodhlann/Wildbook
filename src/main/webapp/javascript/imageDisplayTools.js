/*
 * The goal of this file is to serve as a super lightweight image-handling library for wildbook.
 * Functions will generally take MediaAssets as input, and produce html elements.
 * maLib serves as the package object, containing the namespace
 */

var maLib = {};


/**
 * Builds an html 'figure' element displaying a MediaAsset. This element can be
 * later grabbed by PhotoSwipe to display a lightbox.
 * @param {number} maID - index of the MediaAsset in question
 * @param {DOM} el - the element that will be populated
 */
maLib.maJsonToFigureElem = function(maJson, intoElem) {
  // TODO: copy into html figure element
  var url = maJson.url, w, h;
  // have to check to make sure values exist
  if ('metadata' in maJson) {
    w = maJson.metadata.width;
    h = maJson.metadata.height;
  }
  if (!url || !w || !h) {
    console.log('failed to parse into html this MediaAsset: '+JSON.stringify(maJson));
    return;
  }
  var wxh = w+'x'+h;
  intoElem.append(
    $('<figure itemprop="associatedMedia" itemscope itemtype="http://schema.org/ImageObject" />').append(
      $('<a href="'+url+'" itemprop="contentUrl" data-size="'+wxh+'"/>').append(
        '<img src="'+url+'"itemprop="contentUrl" alt="Image description"/>'
      )
    )
  );
  console.log('\nMediaAsset '+maJson.id+' has children: '+maJson.children);
  console.log('\nMediaAsset '+maJson.id+' has child url: '+maLib.getChildUrl(maJson, '_watermark'));
  return;
}

maLib.maJsonToFigureElemDisplayChild = function(maJson, intoElem, childLabel) {
  // TODO: copy into html figure element
  var url = maJson.url, w, h;
  // have to check to make sure values exist
  if ('metadata' in maJson) {
    w = maJson.metadata.width;
    h = maJson.metadata.height;
  }
  if (!url || !w || !h) {
    console.log('failed to parse into html this MediaAsset: '+JSON.stringify(maJson));
    return;
  }
  var wxh = w+'x'+h;
  intoElem.append(
    $('<figure itemprop="associatedMedia" itemscope itemtype="http://schema.org/ImageObject" />').append(
      $('<a href="'+url+'" itemprop="contentUrl" data-size="'+wxh+'"/>').append(
        '<img src="'+url+'"itemprop="contentUrl" alt="Image description"/>'
      )
    )
  );
  return;
}

/**
 * @param {JSON} maJson - a media asset
 * @param {string} _label - a label such as '_watermark', '_original' or '_thumbnail'
 * @return {boolean}
 */
maLib.hasLabel = function (maJson, _label) {
  try {
    return ('labels' in maJson && _label in maJson.labels);
  } catch (e) {
    return false
  }
}

/**
 * BROKEN! TODO: fix this :^)
 * @param {JSON} maJson - a media asset
 * @param {string} _label - a label such as '_watermark', '_original' or '_thumbnail'
 * @return {JSON} the mediaAsset (or empty object) containing that child
 */
maLib.getChildWithLabel = function (maJson, _label) {
  for (child in maJson.children) {
    console.log('\nchild: '+JSON.stringify(child)); // this line does not work as expected
    if (maLib.hasLabel(child, _label)) return child;
  }
  return null;
}

/**
 * @param {JSON} maJson - a media asset
 * @param {string} _label - a label such as '_watermark', '_original' or '_thumbnail'
 * @return {boolean}
 */
maLib.hasChildWithLabel = function (maJson, _label) {
  return (maLib.getChildWithLabel(maJson, _label) != null);
}

/**
 * @param {JSON} maJson - a media asset
 * @param {string} _label - a label such as '_watermark', '_original' or '_thumbnail'
 * @return string - the url of the picture depicting the labeled child
 */
maLib.getChildUrl = function (maJson, _label) {
  console.log('getChildUrl');
  console.log('\tchildren: '+maJson.children)
  var child = maLib.getChildWithLabel(maJson,_label);
  if (child != null && 'url' in child) {
    return (child.url);
  }
  return '';
}

/**
 * This crucial function (barely modified from PhotoSwipe's public example code) grabs an html div
 * that is especially formatted, and launches photoswipe from that div
 * @param {string} gallerySelector - selector that will grab gallery DOMs from the webpage
 */
maLib.initPhotoSwipeFromDOM = function(gallerySelector) {
  // parse slide data (url, title, size ...) from DOM elements
  // (children of gallerySelector)
  var parseThumbnailElements = function(el) {
      var thumbElements = el.childNodes,
          numNodes = thumbElements.length,
          items = [],
          figureEl,
          linkEl,
          size,
          item;

      for(var i = 0; i < numNodes; i++) {

          figureEl = thumbElements[i]; // <figure> element

          // include only element nodes
          if(figureEl.nodeType !== 1) {
              continue;
          }

          linkEl = figureEl.children[0]; // <a> element

          size = linkEl.getAttribute('data-size').split('x');

          // create slide object
          item = {
              src: linkEl.getAttribute('href'),
              w: parseInt(size[0], 10),
              h: parseInt(size[1], 10)
          };



          if(figureEl.children.length > 1) {
              // <figcaption> content
              item.title = figureEl.children[1].innerHTML;
          }

          if(linkEl.children.length > 0) {
              // <img> thumbnail element, retrieving thumbnail url
              item.msrc = linkEl.children[0].getAttribute('src');
          }

          item.el = figureEl; // save link to element for getThumbBoundsFn
          items.push(item);
      }

      return items;
  };

  // find nearest parent element
  var closest = function closest(el, fn) {
      return el && ( fn(el) ? el : closest(el.parentNode, fn) );
  };

  // triggers when user clicks on thumbnail
  var onThumbnailsClick = function(e) {
      e = e || window.event;
      e.preventDefault ? e.preventDefault() : e.returnValue = false;

      var eTarget = e.target || e.srcElement;

      // find root element of slide
      var clickedListItem = closest(eTarget, function(el) {
          return (el.tagName && el.tagName.toUpperCase() === 'FIGURE');
      });

      if(!clickedListItem) {
          return;
      }

      // find index of clicked item by looping through all child nodes
      // alternatively, you may define index via data- attribute
      var clickedGallery = clickedListItem.parentNode,
          childNodes = clickedListItem.parentNode.childNodes,
          numChildNodes = childNodes.length,
          nodeIndex = 0,
          index;

      for (var i = 0; i < numChildNodes; i++) {
          if(childNodes[i].nodeType !== 1) {
              continue;
          }

          if(childNodes[i] === clickedListItem) {
              index = nodeIndex;
              break;
          }
          nodeIndex++;
      }



      if(index >= 0) {
          // open PhotoSwipe if valid index found
          openPhotoSwipe( index, clickedGallery );
      }
      return false;
  };

  // parse picture index and gallery index from URL (#&pid=1&gid=2)
  var photoswipeParseHash = function() {
    var hash = window.location.hash.substring(1),
    params = {};
    console.log('photoswipeParseHash hash = '+hash);

    if(hash.length < 5) {
      console.log('\thash length is short--returning empty parameters');
      return params;
    }

    var vars = hash.split('&');
    for (var i = 0; i < vars.length; i++) {
      if(!vars[i]) {
        continue;
      }
      var pair = vars[i].split('=');
      if(pair.length < 2) {
        continue;
      }
      params[pair[0]] = pair[1];
    }

    if(params.gid) {
        params.gid = parseInt(params.gid, 10);
    }
    return params;
  };

  var openPhotoSwipe = function(index, galleryElement, disableAnimation, fromURL) {
    var pswpElement = document.querySelectorAll('.pswp')[0],
        gallery,
        options,
        items;
    items = parseThumbnailElements(galleryElement);
    // define options (if needed)
    options = {
      // define gallery index (for URL)
      galleryUID: galleryElement.getAttribute('data-pswp-uid'),
      getThumbBoundsFn: function(index) {
        // See Options -> getThumbBoundsFn section of documentation for more info
        var thumbnail = items[index].el.getElementsByTagName('img')[0], // find thumbnail
          pageYScroll = window.pageYOffset || document.documentElement.scrollTop,
          rect = thumbnail.getBoundingClientRect();
        return {x:rect.left, y:rect.top + pageYScroll, w:rect.width};
      }
    };
    // PhotoSwipe opened from URL
    if(fromURL) {
      if(options.galleryPIDs) {
        // parse real index when custom PIDs are used
        // http://photoswipe.com/documentation/faq.html#custom-pid-in-url
        for(var j = 0; j < items.length; j++) {
          if(items[j].pid == index) {
            options.index = j;
            break;
          }
        }
      } else {
        // in URL indexes start from 1
        options.index = parseInt(index, 10) - 1;
      }
    } else {
      options.index = parseInt(index, 10);
    }
    // exit if index not found
    if( isNaN(options.index) ) {
      return;
    }
    if(disableAnimation) {
      options.showAnimationDuration = 0;
    }

    // Pass data to PhotoSwipe and initialize it
    gallery = new PhotoSwipe( pswpElement, PhotoSwipeUI_Default, items, options);
    gallery.init();
  };

  // loop through all gallery elements and bind events
  var galleryElements = document.querySelectorAll( gallerySelector );

  for(var i = 0, l = galleryElements.length; i < l; i++) {
    galleryElements[i].setAttribute('data-pswp-uid', i+1);
    galleryElements[i].onclick = onThumbnailsClick;
  }

  // Parse URL and open gallery if it contains #&pid=3&gid=1
  var hashData = photoswipeParseHash();
  if(hashData.pid && hashData.gid) {
    console.log('\tabout to call openPhotoSwipe');
    openPhotoSwipe( hashData.pid ,  galleryElements[ hashData.gid - 1 ], true, true );
  }
};

// execute above function

$(document).ready(function() {
  maLib.initPhotoSwipeFromDOM('.my-gallery');
});
