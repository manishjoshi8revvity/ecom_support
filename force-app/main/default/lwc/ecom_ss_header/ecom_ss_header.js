import { LightningElement } from "lwc";
import IMAGES from "@salesforce/resourceUrl/ecom_ss_static_files";
import backToSiteUrl from "@salesforce/label/c.ECOM_Self_Service_Back_to_site_URL";
import backToSiteText from "@salesforce/label/c.ECOM_Self_Service_Back_to_site_Text";
import logoLinkUrl from "@salesforce/label/c.ECOM_Self_Service_Logo_Link_URL";
import { ecom_ss_GetDataFromSession } from "c/ecom_ss_utils";
import { sessionAuthDataKey } from "c/ecom_ss_utils";

export default class Ecom_ss_header extends LightningElement {
  logoUrl = IMAGES + "/revvity-logo.svg";

  userInitials = '';
  userLoggedIn = false;

  windowWidth = window.innerWidth;

  lineCurvedPath =
    "c 2.312 0 4.418 1.3281 5.415 3.4141 l 11.338 23.7401 c 1.184 2.478 4.734 2.4122 5.824 -0.108 l 10.142 -23.4295 c 0.95 -2.1955 3.114 -3.6167 5.506 -3.6167";

  get lineViewBox() {
    return `0 0 ${this.windowWidth} 34`;
  }

  get linePath() {
    return `M 0 1 H ${this.windowWidth * 0.8} ${this.lineCurvedPath} H ${this.windowWidth}`;
  }

  updateWindowWidth() {
    this.windowWidth = window.innerWidth;
  }

  handleLogOut() {
    localStorage.removeItem(sessionAuthDataKey);
    location.href = (location.pathname.includes('/selfservice') ? '/selfservice/':'/');
  }

  connectedCallback() {
    window.addEventListener("resize", this.updateWindowWidth.bind(this));

    ecom_ss_GetDataFromSession()
      .then(data => {
        if(data.success) {
          this.userLoggedIn = true;

          let name = data.fullName || data.name;

          this.userInitials =
            name?.trim()
              .split(' ').filter(i => i.length).map(i => i[0]).slice(0, 2).join('').toUpperCase();
        }
      }).catch(() => {});
  }

  disconnectedCallback() {
    window.removeEventListener("resize", this.updateWindowWidth);
  }

  fixURLPath(url) {
    return (
      (url.startsWith('/') && location.pathname.includes('/selfservice'))
      ? `/selfservice${url}`
      : url
    )
  }

  backToSite = {
    url: this.fixURLPath(backToSiteUrl),
    text: backToSiteText,
    show: backToSiteUrl && backToSiteText,
    logoLink: this.fixURLPath(logoLinkUrl)
  };
}