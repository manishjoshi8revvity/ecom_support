import { LightningElement } from "lwc";
import IMAGES from "@salesforce/resourceUrl/ecom_ss_static_files";
import getUserData from "@salesforce/apex/ECOM_SelfServiceController.getUserData";

export default class Ecom_ss_utils extends LightningElement {}

export const sessionAuthDataKey = 'sessionAuthData';
export const sessionAuthStateKey = 'sessionAuthState';
export const sessionAuthNonceKey = 'sessionAuthNonce';

export function ecom_ss_ImageUrl(inputData) {
  if (!inputData) {
    return false;
  }

  inputData = inputData.trim();

  if (inputData.startsWith("https://") || inputData.startsWith("http://")) {
    return inputData;
  }

  return IMAGES + (inputData.startsWith("/") ? "" : "/") + inputData;
}

export function ecom_ss_GetDataFromSession() {
  return new Promise(async (resolve, reject) => {
    let sessionAuthData = localStorage.getItem(sessionAuthDataKey);
    if (sessionAuthData) {
      try {
        let userData = await getUserData({ encryptedData: sessionAuthData });
        if (userData.success && userData.name) {
          resolve(userData);
        } else {
          throw new Error("Could not retrieve data");
        }
      } catch (e) {
        console.error(e.message);
        localStorage.removeItem("sessionAuthData");
        reject(e.message);
      }
    } else {
      resolve({});
    }
  });
}

function transformElement(element, transformValue) {
  element.style.transform = transformValue;
}

/**
 * @param {HTMLElement} movingEl
 * @param {HTMLElement} triggerEl
 * @param {Number} maxX
 * @param {Number} maxY
 * @param {Boolean} moveOpposite
 * @returns {undefined}
 */
export function ecom_ss_PointerFollowAimation(movingEl, triggerEl, maxX, maxY, moveOpposite = true) {
  triggerEl.addEventListener('mousemove', (e) => {
    let rect = triggerEl.getBoundingClientRect();

    let xPct = Math.min(Math.max((e.clientX - rect.left) / rect.width, 0), 1);
    let yPct = Math.min(Math.max((e.clientY - rect.top) / rect.height, 0), 1);

    let moveFactor = moveOpposite ? -1 : 1;

    let translateX = moveFactor * ((maxX * 2 * xPct) - maxX);
    let translateY = moveFactor * ((maxY * 2 * yPct) - maxY);

    let translateString =
      `translate(${translateX}px, ${translateY}px)`;

    window.requestAnimationFrame(transformElement.bind(this, movingEl, translateString));
  });

  triggerEl.addEventListener('mouseleave', () => {
    window.requestAnimationFrame(transformElement.bind(this, movingEl, null));
  });
}