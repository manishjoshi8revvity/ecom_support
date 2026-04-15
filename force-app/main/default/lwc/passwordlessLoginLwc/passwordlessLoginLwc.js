import { LightningElement, track } from 'lwc';
import initiateLogin from "@salesforce/apex/PasswordlessLogin.initiateLogin";
import verifyPasswordlessLogin from "@salesforce/apex/PasswordlessLogin.verifyPasswordlessLogin";
import loginAsUserAndRedirect from "@salesforce/apex/PasswordlessLogin.loginAsUserAndRedirect";

export default class PasswordlessLoginLwc extends LightningElement {
    @track loginOption = 'Email';
    @track email = '';
    @track phone = '';
    @track identifier ='';
    @track authorizationMethod = 'Email';
    @track token = '';
    @track otp = '';
    showSpinner = false;
    showErrorMessage = false;
    errorMessage = '';
    loginPage = true;
    otpPage = false;
    disableVerifyButton = false;

    get isEmailSelected() {
        return this.loginOption === 'Email';
    }

    get isSmsSelected() {
        return this.loginOption === 'SMS';
    }

    // keep method (won’t be triggered because radios are disabled)
    handleOptionChange(event) {
        this.loginOption = event.target.value;
        this.authorizationMethod = this.loginOption; // keeps logic consistent if re-enabled later
    }

    handleOtpChange(event) {
        this.otp = event.target.value;
        console.log('OTP  -> ', this.otp);
        if (this.otp.length == 6) {
            this.disableVerifyButton = false;
            console.log('this.disableVerifyButton ', this.disableVerifyButton);
        }
    }

    handleIdentifier(event) {
        this.identifier = event.target.value;
        console.log('Identifier value -> ', this.identifier);
    }

    handleSendOtp() {
        this.showSpinner = true;
        if (this.identifier && this.identifier.trim() != '') {
            this.showErrorMessage = false;
            this.clearErrorMessages();
            // Enforce Email method since UI is locked
            this.loginOption = 'Email';
            this.authorizationMethod = 'Email';

            if (this.isEmailSelected) {
                console.log('Sending OTP to Email:', this.email);
            } else if (this.isSmsSelected) {
                console.log('Sending OTP to Phone:', this.phone);
            }

            initiateLogin({
                identifier: this.identifier,
                authorizationMethod: this.authorizationMethod
            })
            .then(result => {
                console.log('Result -> ', result);
                this.token = result;
                let tokenRegex = /^[A-Za-z0-9]{20}$/;
                if (this.token && this.token.match(tokenRegex)) {
                    console.log('Valid token!');
                    this.otpPage = true;
                    this.loginPage = false;
                } else if (result.includes('Phone not registered')) {
                    this.clearErrorMessages();
                    this.showErrorMessage = true;
                    this.errorMessage = 'Phone not registered , Please register and verify your phone number and try again.';
                } else if (result.includes('Email Sent for verification')) {
                    this.clearErrorMessages();
                    this.showErrorMessage = true;
                    this.errorMessage = 'Email Sent for verification, please click on link received in the email for verification.';
                } else if (result.includes('Email not registered / User does not exist')) {
                    this.clearErrorMessages();
                    this.showErrorMessage = true;
                    this.errorMessage = 'Email not registered / User does not exist. Please register and try again.';
                } else {
                    this.clearErrorMessages();
                    this.showErrorMessage = true;
                    this.errorMessage = 'Some Error Occurred , Please try again later.';
                    console.log('Invalid token!');
                }
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('error -> ', error);
                this.showSpinner = false;
            });
        } else {
            this.clearErrorMessages();
            this.showErrorMessage = true;
            this.errorMessage = 'Please enter a valid email address.';
            this.showSpinner = false;
            return;
        }
    }

    handleVerifyOtp() {
        this.showSpinner = true;
        verifyPasswordlessLogin({
            identifier: this.identifier,
            otp: this.otp,
            authorizationMethod: this.authorizationMethod,
            token: this.token
        })
        .then(result => {
            console.log('Result -> ', result);

            if (result.includes('https')) {
                console.log('Verification successful');
                window.location.href = result;
            } else if (result.includes('Invalid verification code') || result.includes('Verification code missing')) {
                this.clearErrorMessages();
                this.showErrorMessage = true;
                this.errorMessage = 'Invalid code, please try again.';
                this.disableVerifyButton = true;
            } else if (result.includes('Too many attempts')) {
                this.clearErrorMessages();
                this.showErrorMessage = true;
                this.errorMessage = 'Too many attempts, please use resend button and try again.';
                this.disableVerifyButton = true;
            } else {
                this.clearErrorMessages();
                this.showErrorMessage = true;
                this.errorMessage = 'Some Error Occurred , Please contact your System Administrator.';
                console.log('Verification failed');
            }
            this.showSpinner = false;
        }).catch(error => {
            console.error('error -> ', error);
            this.showSpinner = false;
        });
    }

    backButton() {
        this.otpPage = false;
        this.loginPage = true;
        this.showErrorMessage = false;
        this.clearErrorMessages
    }

    clearErrorMessages() {
        this.errorMessage = '';
    }

    handleMagicLinkLogin(event) {
        this.showSpinner = true;
        if (this.identifier && this.identifier.trim() != '') {
            const source = event?.currentTarget?.dataset?.source;
            console.log('Magic Link Login Source: ', source);
            let sendEmail = false;
            if (source == 'email') {
                sendEmail = true;
            }

            console.log('FINAL USER EMAIL = ', this.identifier);
            console.log('FINAL SEND EMAIL = ', sendEmail);
            loginAsUserAndRedirect({
                userEmail : this.identifier,
                sendEmail: sendEmail
            })
            .then(result => {
                console.log('Magic Link Login Result -> ', result);
                if (result && result.includes('https')) {
                    console.log('Magic Link Login URL generated successfully');
                    window.location.href = result;
                } else if (result && result.includes('Email Sent for verification')) {
                    this.clearErrorMessages();
                    this.showErrorMessage = true;
                    this.errorMessage = 'Email Sent, please click on link received in the email for login.';
                } else if (result && result.includes('User/Email not found')) {
                    this.clearErrorMessages();
                    this.showErrorMessage = true;
                    this.errorMessage = 'Email not registered / User does not exist. Please register and try again.';
                } else {
                    this.clearErrorMessages();
                    this.showErrorMessage = true;
                    this.errorMessage = 'Some Error Occurred , Please try again later.';
                    console.log('Magic Link Login failed');
                }
                this.showSpinner = false;
            })
            .catch(error => {
                console.error('error -> ', error);
                this.showSpinner = false;
            });
        } else {
            this.clearErrorMessages();
            this.showErrorMessage = true;
            this.errorMessage = 'Please enter a valid email address.';
            this.showSpinner = false;
            return;
        }
    }
}