import { LightningElement} from 'lwc';
    import basePath from '@salesforce/community/basePath';
    import LBL_SESSION_TIMEOUT from '@salesforce/label/c.ECOM_Session_Timeout_Cookie';
    import ECOM_Session_Time_Out_Minutes from '@salesforce/label/c.ECOM_Session_Time_Out_Minutes';

    export default class Ecom_sessionTimeoutRedirect extends LightningElement {

        labels = {
            LBL_SESSION_TIMEOUT,
            ECOM_Session_Time_Out_Minutes
        }

        intervalId;
        inactivityTimer;
        showPopup = false;
        domainName = '.revvity.com';
        connectedCallback() {
            // Start checking every 5 seconds
            this.intervalId = setInterval(() => {
                this.checkCookieTime();
            }, 5000);
        }

        disconnectedCallback() {
            // Clear interval when component is destroyed
            clearInterval(this.intervalId);
        }

        handleContinue(){
            this.showPopup = false;
            this.updateTimestamp();
        }

        handleLogout(){
            this.showPopup = false;
            this.redirectToLogin();
        }

        updateTimestamp() {
        let cookieName = this.labels.LBL_SESSION_TIMEOUT;
        const secondsTimestamp = Math.floor(Date.now() / 1000);
        this.setCookie(cookieName, secondsTimestamp, 1);
        }

        setCookie(name, value, days) {
            let expires = "";
            if (days) {
                const date = new Date();
                // 2025 Standard: Ensure expiry is calculated accurately
                date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
                expires = "; expires=" + date.toUTCString();
            }

            // Updated with domain attribute
            document.cookie = `${name}=${value}${expires}; path=/; domain=${this.domainName}; SameSite=Lax; Secure`;
            
            console.log(`Cookie ${name} updated for domain ${this.domainName}`);
        }

        //RWPS-2271-START
        checkCookieTime() {
            // Get the cookie value
            const cookieName = this.labels.LBL_SESSION_TIMEOUT;
            const cookieValue = this.getCookie(cookieName);
            if (cookieValue) {
                const cookieTimestamp = parseInt(cookieValue, 10); // Convert to number
                const currentTimestamp = Math.floor(Date.now() / 1000); // Convert to seconds

                // Check if 25 minutes have passed
                const timeDifference = currentTimestamp - cookieTimestamp;
                const diffMinutes = Math.floor(timeDifference / 60);
                const timeoutMinutes =  this.labels.ECOM_Session_Time_Out_Minutes;
                 // 1. If we hit or exceed 30 minutes (timeout + 5), log out
                if (diffMinutes >= timeoutMinutes + 5) {
                    if(this.showPopup){
                       this.handleLogout();
                    }
                    
                } 
                // 2. If we are between 25 and 30 minutes, show the popup
                else if (diffMinutes >= timeoutMinutes) {
                    this.showPopup = true;
                } 
                // 3. If time was reset elsewhere (diff < 25), hide popup and keep checking
                else {
                    this.showPopup = false;
                }
            
            }
        }
          //RWPS-2271-END

        getCookie(name) {
            const value = `; ${document.cookie}`;
            const parts = value.split(`; ${name}=`);
            if (parts.length === 2) return parts.pop().split(';').shift();
            return null;
        }
        
        redirectToLogin() {
            window.location.href = `${basePath}/secur/logout.jsp?retUrl=${basePath}/login?ptcms=true`;
        }

        handleClose(){
        this.redirectToLogin();  
        }
    }