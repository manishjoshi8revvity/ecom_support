import { LightningElement, api } from 'lwc';

export default class Ecom_customFileUpload extends LightningElement {
  @api buttonText = "Upload Files";
  @api dropzoneText = "Or drop files";
  @api accept = "";

  get _accept() {
    if(this.accept && this.accept.join) {
      return this.accept.join(',')
    }
    return '';
  }

  isDragover = 'no';

  handleChange() {
    if(this.refs.fileInput.files) {
      this.dispatchEvent(new CustomEvent('change', {detail: {files: this.refs.fileInput.files}}));
    }
  }

  handleDrag(e) {
    e.preventDefault();
    e.stopPropagation();

    if(e.type == 'dragenter' || e.type == 'dragover') {
      this.isDragover = 'yes';
    } else if(e.type == 'dragleave') {
      this.isDragover = 'no';
    }
  }

  handleDrop(e) {
    e.preventDefault();
    this.isDragover = 'no';

    const files = e.dataTransfer.files;
    if(files.length) {
      const dT = new DataTransfer();
      dT.items.add(files[0]);

      this.refs.fileInput.files = dT.files;
      this.handleChange();
    }
  }
}