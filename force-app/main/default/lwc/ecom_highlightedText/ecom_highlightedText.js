import { api, LightningElement } from 'lwc';

export default class Ecom_highlightedText extends LightningElement {
  @api text = '';
  @api search = '';
  @api highlightFullText;
  @api highlightColor = '#FFEB0F';

  get markStyle() {
    return `
        background-color: ${this.highlightColor};
    `;
  }

  get textArray() {
    let finalSearch = this.search ? this.search.trim() : '';
    let originalText = this.text ? this.text.toString() : '';

    if (!finalSearch || originalText.length === 0) {
      return [{
        key: 'text1',
        text: originalText,
        isHighlighted: false
      }];
    }

    let lowerOriginalText = originalText.toLowerCase();
    let lowerSearch = finalSearch.toLowerCase();

    if (lowerSearch === lowerOriginalText.trim() && !this.highlightFullText) {
      return [{
        key: 'text1',
        text: originalText,
        isHighlighted: false
      }];
    }

    const returnArray = [];
    let currentIndex = 0;
    let matchIndex = -1;

    while ((matchIndex = lowerOriginalText.indexOf(lowerSearch, currentIndex)) !== -1) {
      const searchLength = lowerSearch.length;

      if (matchIndex > currentIndex) {
        returnArray.push({
          key: `text_${currentIndex}`,
          text: originalText.substring(currentIndex, matchIndex),
          isHighlighted: false
        });
      }

      returnArray.push({
        key: `search_${matchIndex}`,
        text: originalText.substring(matchIndex, matchIndex + searchLength),
        isHighlighted: true
      });

      currentIndex = matchIndex + searchLength;
    }

    if (currentIndex < originalText.length) {
      returnArray.push({
        key: `text_end_${currentIndex}`,
        text: originalText.substring(currentIndex),
        isHighlighted: false
      });
    }

    return returnArray;
  }
}