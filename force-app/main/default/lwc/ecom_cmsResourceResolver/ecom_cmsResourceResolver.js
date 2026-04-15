import { getPathPrefix } from 'lightning/configProvider'; // Provides the path prefix to Core resources, like CMS
//import B2B_Theme from '@salesforce/resourceUrl/B2B_Theme';
import FORM_FACTOR from '@salesforce/client/formFactor';

//const defaultNoImage = B2B_Theme + '/img/No_Image.png';
/**
 * Regular expressions for CMS resources and for static B2B image resources -
 * specifically the "no image" image - that we want to handle as though they were CMS resources.
 */
const cmsResourceUrlPattern = /^\/cms\//;
const b2bStaticImageResourcePattern = /^\/img\//;

/**
 * Resolves a URL for a resource that may (or may not) be hosted by Salesforce CMS.
 *
 * @param {string} url
 *  A URL of a resource. This may - or may not - be a Salesforce-hosted CMS resource.
 *
 * @returns {string}
 *  If {@see url} represents a CMS-hosted resource, then a resolved CMS resource URL;
 *  otherwise, the unaltered {@see url}.
 */
export function resolve(url) {
   
    // If the URL is a CMS URL, transform it; otherwise, leave it alone.
    if (
        cmsResourceUrlPattern.test(url) ||
        b2bStaticImageResourcePattern.test(url)
    ) {
        url = `${getPathPrefix()}${url}`;
    }
    //console.log()
  
    // if(url?.indexOf('default-product-image.svg')!==-1 || url===''){
    //     url = defaultNoImage;
    // }
    return url;
}

export function  view (){
    let device = {isDesktop:false,isMobile:false,isTablet:false};
    if(FORM_FACTOR==='Large'){
        device.isDesktop = true;
    }else if(FORM_FACTOR==='Medium'){
        device.isTablet = true;
    }else if(FORM_FACTOR==='Small'){
        device.isMobile = true;
    }
    return device;
}