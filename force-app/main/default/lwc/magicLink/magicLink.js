import { LightningElement, wire } from 'lwc';
import processMagicLink from "@salesforce/apex/PasswordlessLogin.processMagicLink";
import loginAsUserAndRedirect from "@salesforce/apex/PasswordlessLogin.loginAsUserAndRedirect";
import { CurrentPageReference } from "lightning/navigation";

export default class MagicLink extends LightningElement {

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {/* 
        console.log('FINAL TOKEN -->', this.currentPageReference.state['token']);
        console.log('FINAL TOKEN -->', this.currentPageReference.state['retURL']);
        if(this.currentPageReference && this.currentPageReference.state['token']) {
            processMagicLink({
            jwt: this.currentPageReference.state['token'],
            retURL: this.currentPageReference.state['retURL']
            }).then(result => {
                console.log('FINAL RESUT-->', result);
                window.open(result, "_self");
            }).catch(err => {
                console.log('FINAL ERROR-->', err);
            });
        } else {
            console .log('No token found in URL');
        } */

        console.log('FINAL LOGIC-->');
        loginAsUserAndRedirect({})
        .then(result => {
            console.log('FINAL RESUT-->', result);
            window.open(result, "_self");
        }).catch(err => {
            console.log('FINAL ERROR-->', err);
        });
    }

   /*  handleRedirect() {
        console.log('FINAL TOKEN -->', this.currentPageReference.state['token']);
        console.log('FINAL TOKEN -->', this.currentPageReference.state['retURL']);
    } */
}