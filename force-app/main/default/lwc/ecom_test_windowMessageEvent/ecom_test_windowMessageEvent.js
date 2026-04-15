import { LightningElement } from 'lwc';

export default class Ecom_test_windowMessageEvent extends LightningElement {
  message = 'no message';

  connectedCallback() {
    window.addEventListener('message', this.receiveMsg.bind(this))
  }
  disconnectedCallback() {
    window.removeEventListener('message', this.receiveMsg)
  }

  receiveMsg(event) {
    if(!event.origin.includes('secure')) {
      console.log(123, event);
      this.message = event.data
      window.parent.postMessage('test message', '*')
    }
  }
}