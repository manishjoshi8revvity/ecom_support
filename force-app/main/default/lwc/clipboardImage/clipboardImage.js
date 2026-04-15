import { LightningElement, api } from 'lwc';

export default class ClipboardImage extends LightningElement {
    imageData;

    @api imageURL; // Expose imageURL for Flow Output
    @api imageTitle; // Expose imageTitle for Flow Input
    @api imageDataOutput; // Expose imageData for Flow Output

    handlePaste(event) {
        const clipboardItems = event.clipboardData.items;
        for (let item of clipboardItems) {
            if (item.type.indexOf('image') !== -1) {
                const file = item.getAsFile();
                const reader = new FileReader();

                reader.onload = () => {
                    this.imageData = reader.result; // Store Base64 image data
                    this.imageDataOutput = this.imageData; // Expose image data for Flow Output
                };

                reader.readAsDataURL(file);
            }
        }
    }
}