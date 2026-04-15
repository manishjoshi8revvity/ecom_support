import { LightningElement ,api} from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class Lwc_colproc_findcommonstrings extends LightningElement {

    @api inputStringList1;
    @api inputStringList2;
    @api commonStringList;
    @api uniqueInCollec1;
    @api uniqueInCollec2;
    @api uncommonStringList;
    previousValue;

    get jsonInputValueList() {
        return JSON.stringify(this.inputStringList1) + JSON.stringify(this.inputStringList2);
    }

    getCommon(x, y) {
        if(x == undefined) {
            x = [];
        }
        if(y == undefined) {
            y = [];
        }
        return x.filter(function(val) {
            return y.indexOf(val) != -1;
        });
    }

    getUniqueInCollec1(x, y) {
        if(x == undefined) {
            x = [];
        }
        if(y == undefined) {
            y = [];
        }
        return x.filter(function(val) {
            return y.indexOf(val) == -1;
        });
    }

    getUniqueInCollec2(x, y) {
        if(x == undefined) {
            x = [];
        }
        if(y == undefined) {
            y = [];
        }
        return y.filter(function(val) {
            return x.indexOf(val) == -1;
        });
    }

    renderedCallback() {
        
        if(((this.inputStringList1 != undefined && this.inputStringList2 != undefined) 
        || (this.inputStringList1 == undefined && this.inputStringList2 != undefined)
        || (this.inputStringList1 != undefined && this.inputStringList2 == undefined))
            && this.jsonInputValueList != this.previousValue) {
                
                
                this.previousValue = JSON.stringify(this.inputStringList1) + JSON.stringify(this.inputStringList2);
                
                this.commonStringList = this.getCommon(this.inputStringList1,this.inputStringList2);
                this.dispatchEvent(new FlowAttributeChangeEvent('commonStringList', this.commonStringList.toString()));

                this.uniqueInCollec1 = this.getUniqueInCollec1(this.inputStringList1,this.inputStringList2);
                this.dispatchEvent(new FlowAttributeChangeEvent('uniqueInCollec1', this.uniqueInCollec1.toString()));

                this.uniqueInCollec2 = this.getUniqueInCollec2(this.inputStringList1,this.inputStringList2);
                this.dispatchEvent(new FlowAttributeChangeEvent('uniqueInCollec2', this.uniqueInCollec2.toString()));
                //console.log('values  ' +  this.uniqueInCollec2);
                if(this.uniqueInCollec1 == '' && this.uniqueInCollec2 == '') {
                    this.uncommonStringList = '';
                }
                else if(this.uniqueInCollec2 == '') {
                    this.uncommonStringList = this.uniqueInCollec1;
                }
                else if(this.uniqueInCollec1 == '') {
                    this.uncommonStringList = this.uniqueInCollec2;
                }
                else {
                    this.uncommonStringList = this.uniqueInCollec1 + ',' + this.uniqueInCollec2;
                }
                
                console.log('this.uncommonStringList' + this.uncommonStringList);
                this.dispatchEvent(new FlowAttributeChangeEvent('uncommonStringList', this.uncommonStringList.toString()));
        }
        else{
            console.log('inside else');
            this.previousValue = JSON.stringify(this.inputStringList1) + JSON.stringify(this.inputStringList2);
            this.commonStringList='';
            this.uniqueInCollec1='';
            this.uniqueInCollec2='';
            this.uncommonStringList='';
            this.dispatchEvent(new FlowAttributeChangeEvent('commonStringList', this.commonStringList));
            this.dispatchEvent(new FlowAttributeChangeEvent('uniqueInCollec1', this.uniqueInCollec1));
            this.dispatchEvent(new FlowAttributeChangeEvent('uniqueInCollec2', this.uniqueInCollec2));
            this.dispatchEvent(new FlowAttributeChangeEvent('uncommonStringList', this.uncommonStringList));
        }
        
    }
 
    handleOnChange(event) {
        console.log();
    }
}