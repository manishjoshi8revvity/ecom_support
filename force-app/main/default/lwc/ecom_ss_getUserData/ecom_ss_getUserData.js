import { LightningElement } from "lwc";
import authWithEntra from "@salesforce/apex/ECOM_SelfServiceController.authWithEntra";
import tenantId from "@salesforce/label/c.ECOM_Self_Service_Entra_SSO_Tenant_ID";
import clientId from "@salesforce/label/c.ECOM_Self_Service_Entra_SSO_Client_ID";
import { ecom_ss_GetDataFromSession } from "c/ecom_ss_utils";
import { sessionAuthDataKey, sessionAuthStateKey, sessionAuthNonceKey } from "c/ecom_ss_utils";

export default class Ecom_ss_getUserData extends LightningElement {
  error = false;
  success = false;

  name = "";

  clearSessions(removeAuthData = true) {
    if(removeAuthData) {
      localStorage.removeItem(sessionAuthDataKey);
    }
    localStorage.removeItem(sessionAuthStateKey);
    localStorage.removeItem(sessionAuthNonceKey);
  }

  loginSuccess(loginName = '') {
    this.success = true;
    this.name = loginName;
    this.clearSessions(false);
    location.href = (location.pathname.includes('/selfservice') ? '/selfservice' : '/');
  }

  loginFailure(logData) {
    if(logData) {
      console.error(logData);
    }
    this.clearSessions();
    this.error = true;
  }

  async connectedCallback() {
    let hashSplit = location.hash.replace("#", "").split("&");
    location.hash = "";

    let sessionData = localStorage.getItem(sessionAuthDataKey);
    if (sessionData) {
      try {
        let userData = await ecom_ss_GetDataFromSession();
        if (userData.success) {
          this.loginSuccess(userData.name);
          return;
        }
      } catch (e) {}
    }

    let accessToken = "";
    let idToken = "";
    let state = "";

    for (let i = 0; i < hashSplit.length; i++) {
      let [label, value] = hashSplit[i].split("=");
      if(value) {
        if (label == "access_token") {
          accessToken = value;
        } else if (label == "id_token") {
          idToken = value;
        } else if (label == "state") {
          state = value;
        }
      }

      if (idToken && accessToken && state) {
        break;
      }
    }

    if (
      !(idToken && accessToken && state) ||
      state != localStorage.getItem(sessionAuthStateKey)
    ) {
      this.loginFailure("Incomplete data received from SSO");
      return;
    }

    let tokenData = {};
    try {
      tokenData = JSON.parse(atob(idToken.split(".")[1]));

      if (
        !tokenData.email ||
        !tokenData.email.endsWith("@revvity.com") ||
        !tokenData.nonce ||
        tokenData.nonce != localStorage.getItem(sessionAuthNonceKey) ||
        !tokenData.sub ||
        tokenData.tid != tenantId ||
        tokenData.aud != clientId
      ) {
        throw new Error("Incorrect data received from SSO");
      }
    } catch (e) {
      this.loginFailure(e.message);
      return;
    }

    authWithEntra({ accessToken, email: tokenData.email, sub: tokenData.sub })
      .then((data) => {
        if (data.success) {
          localStorage.setItem(sessionAuthDataKey, data.enc);
          this.loginSuccess(data.name);
        } else {
          throw new Error("Could not get account information.");
        }
      })
      .catch((e) => {
        this.loginFailure(e.message);
      });
  }
}