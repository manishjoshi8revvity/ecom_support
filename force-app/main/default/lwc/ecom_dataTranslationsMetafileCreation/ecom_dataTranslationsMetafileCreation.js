import { LightningElement } from 'lwc';
let XLS = {};
import sheetjs from '@salesforce/resourceUrl/ssrc_ECOM_Sheetjs';
import { loadScript } from 'lightning/platformResourceLoader';
export default class Ecom_dataTranslationsMetafileCreation extends LightningElement {
    acceptedFormats = ['.csv','.xls', '.xlsx'];

    connectedCallback(){
        Promise.all([
            loadScript(this, sheetjs + '/sheetjs/sheetmin.js')
            ]).then(() => {
                XLS = XLSX;
            })
    }

    handleFileUpload(event) {
        const files = event.detail.files;
        this.errorMessage = [];
        if (files.length > 0) {
          if(files.length>1)
          {
            return;
          } 
          const file = files[0];
          // start reading the uploaded csv file
          if( file?.type==='text/csv'){
            this.read(file);
          }
          else if(file?.type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' || file?.type === 'application/vnd.ms-excel'){
            this.ExcelToJSON(file);
        }
          else{
            this.handleNextSteps();
            this.errorMessage.push('Only .csv, .xls, .xlsx files are supported.');
            this.showUploadModal=false;
            this.showErrorMessage=true;
            return;
          }        
        }
    }

    async read(file) {
        try {
          const result = await this.load(file);
            // Check if there is only one line (which means the file is empty)
            let fileContent = result;
            const lines = fileContent.split('\n');
            let isCSVFileEmpty = lines.length < 3;
          if(isCSVFileEmpty)
          {
            this.template.querySelector('c-ecom_show-Toast').showToast('Please Upload File with Part Number and Quantity', 'error');
            return;
          }
          else
          {
             // execute the logic for parsing the uploaded csv file
            this.parse(result);
          }
        } catch (e) {
          this.error = e;
        }
      }

      parse(csv){
        this.showSpinner=true;
        // parse the csv file and treat each line as one item of an array
        const lines = csv.split(/\r\n|\n/);
        
        // parse the first line containing the csv column headers
        const headers = lines[0].split(',');
        
        // iterate through csv headers and transform them to column format supported by the datatable
        this.columns = headers.map((header) => {
          return { label: header, fieldName: header };
        });
      
        const data = [];
        
        // iterate through csv file rows and transform them to format supported by the datatable
        lines.forEach((line, i) => {
          if (i === 0) 
          {
            return;
          }
      
          const obj = {};
          const currentline = line.split(',');
          let hasData = false;
          for (let j = 0; j < headers.length; j++) {
            if(currentline[j] && currentline[j].trim()!==''){
                        hasData = true; 
                        obj[headers[j]] = currentline[j];
                    }
                }
            if(hasData){
                data.push(obj);
            }
        });
       
      }

      ExcelToJSON(file){
        var reader = new FileReader();
        reader.onload = event => {
            var data=event.target.result;
            var workbook=XLS.read(data, {
                type: 'binary'
            });
            var XL_row_object = XLS.utils.sheet_to_row_object_array(workbook.Sheets["Sheet1"]);
            var data = JSON.stringify(XL_row_object);
            const rawData = JSON.parse(data);
            this.formatData(rawData);
        };
        reader.onerror = function(ex) {
            this.error=ex;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error while reding the file',
                    message: ex.message,
                    variant: 'error',
                }),
            );
        };
        reader.readAsBinaryString(file);
    }

    formatData(data){
        var formattedData;
        var keysArray = [];
        data.forEach((element, index, array) => {
            keysArray = Object.keys(element);
            //formattedData += element.PartNumber + ',' + element.Qty + '\n';
        });
        formattedData = keysArray[0] + ',' + keysArray[1] + '\n';
        let parentTag = '<customLabels>'+'\n';
        let child1Tag = '\t'+'<label>';
        let child1TagClosing = '</label>'+'\n';
        let child2Tag = '\t'+'<name>';
        let child2TagClosing = '</name>'+'\n';
        let parentTagClosing = '</customLabels>'+'\n';
        data.forEach((element, index, array) => {           
            keysArray = Object.keys(element);
            console.log(typeof (element.TRANSLATION)+'-------'+element.LabelKey);
            if(element.TRANSLATION!==undefined && element.TRANSLATION!=null){
                let labelValue = element.TRANSLATION!==undefined && typeof (element.TRANSLATION) == "string"?element.TRANSLATION.trim():element.TRANSLATION;
                let labelKey  =  element.LabelKey!==undefined && typeof (element.LabelKey) == "string"?element.LabelKey.trim():element.LabelKey;
                formattedData += parentTag+child1Tag+labelValue+child1TagClosing+child2Tag+labelKey+child2TagClosing+parentTagClosing;
            }            
        });
        console.log(formattedData);
    }
}