import { LightningElement, api } from "lwc";
import tenantId from "@salesforce/label/c.ECOM_Self_Service_Entra_SSO_Tenant_ID";
import clientId from "@salesforce/label/c.ECOM_Self_Service_Entra_SSO_Client_ID";
import { sessionAuthStateKey, sessionAuthNonceKey } from "c/ecom_ss_utils";

export default class Ecom_ss_SsoRedirection extends LightningElement {
  @api buttonText = "Revvity SSO";

  sessionVerifyFormat = new Intl.NumberFormat("en-US", {
    minimumIntegerDigits: 5,
    maximumFractionDigits: 0,
  });

  getSessionVerifyValue(max=100000) {
    return this.sessionVerifyFormat.format(Math.random() * max).replaceAll(",", "");
  }

  connectedCallback() {
    let state = this.getSessionVerifyValue();
    let nonce = this.getSessionVerifyValue();

    localStorage.setItem(sessionAuthStateKey, state);
    localStorage.setItem(sessionAuthNonceKey, nonce);

    let redirectUrl =
      location.origin + (location.pathname.includes('/selfservice') ? '/selfservice/':'/') + 'get-user-data';

    location.href = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/authorize?client_id=${clientId}&response_type=id_token%20token&redirect_uri=${encodeURIComponent(redirectUrl)}&response_mode=fragment&scope=openid+profile+email&state=${state}&nonce=${nonce}`;
  }
}