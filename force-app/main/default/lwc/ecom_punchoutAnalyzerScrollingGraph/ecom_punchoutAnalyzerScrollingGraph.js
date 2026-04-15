import { api, LightningElement } from "lwc";

export default class Ecom_punchoutAnalyzerScrollingGraph extends LightningElement {
  @api customerCount = 0;
  @api maxBarsToShow = 10;

  @api resetScroll() {
    this.scrollerTopPct = 0;
  }

  graphMousedown = false;
  graphScrollBuffer = 0;
  scrollerTopPct = 0;

  get showChartScroll() {
    return this.customerCount && this.customerCount > this.maxBarsToShow;
  }

  get chartScrollerHeight() {
    return this.customerCount > 0 ? this.maxBarsToShow / this.customerCount : 0;
  }

  get scrollerStyle() {
    let styleString = "";
    styleString += `height: ${this.chartScrollerHeight * 100}%;`;
    styleString += `top: ${this.scrollerTopPct * 100}%;`;
    styleString += this.graphMousedown ? `transition: 0s;` : "";
    return styleString;
  }

  get maxScrollerTop() {
    return 1 - this.chartScrollerHeight;
  }

  get customerLastIndex() {
    return this.customerCount - 1;
  }

  handleScrollBarClick(e) {
    let scrollerRectTop = this.refs.scroller.getBoundingClientRect().top;
    let scrollBarRect = this.refs.scrollBar.getBoundingClientRect();

    let currentTopPct =
      (scrollerRectTop - scrollBarRect.top) / scrollBarRect.height;

    let clientY = e.clientY;

    let newTop;

    if (clientY > scrollerRectTop) {
      newTop = currentTopPct + this.chartScrollerHeight;
    } else {
      newTop = currentTopPct - this.chartScrollerHeight;
    }

    this.moveScroller(Math.min(Math.max(newTop, 0), this.maxScrollerTop));
  }

  handleScrollerClick(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  handleScrollerMouseDown(e) {
    e.preventDefault();

    this.graphMousedown = true;

    this.graphScrollBuffer =
      e.clientY - this.refs.scroller.getBoundingClientRect().top;
  }

  #handleDocumentMouseUp;
  #handleDocumentMouseLeave;
  #handleDocumentMouseMove;
  connectedCallback() {
    this.#handleDocumentMouseUp = this.handleDocumentMouseUpAndLeave.bind(this);
    document.addEventListener("mouseup", this.#handleDocumentMouseUp);

    this.#handleDocumentMouseLeave =
      this.handleDocumentMouseUpAndLeave.bind(this);
    document.addEventListener("mouseleave", this.#handleDocumentMouseLeave);

    this.#handleDocumentMouseMove = this.handleDocumentMouseMove.bind(this);
    document.addEventListener("mousemove", this.#handleDocumentMouseMove);
  }

  disconnectedCallback() {
    document.removeEventListener("mouseup", this.#handleDocumentMouseUp);
    document.removeEventListener("mouseleave", this.#handleDocumentMouseLeave);
    document.removeEventListener("mousemove", this.#handleDocumentMouseMove);
  }

  handleDocumentMouseUpAndLeave(e) {
    if (this.graphMousedown) {
      this.graphMousedown = false;
    }
  }

  handleDocumentMouseMove(e) {
    if (!this.graphMousedown) {
      return;
    }

    let scrollBarRect = this.refs.scrollBar.getBoundingClientRect();

    let newTop =
      (e.clientY - this.graphScrollBuffer - scrollBarRect.top) /
      scrollBarRect.height;

    this.moveScroller(Math.min(Math.max(newTop, 0), this.maxScrollerTop));
  }

  moveScroller(top) {
    this.scrollerTopPct = top;

    let minY = Math.ceil(top * this.customerCount);
    let maxY = minY + this.maxBarsToShow - 1;

    if (maxY > this.customerLastIndex) {
      maxY = this.customerLastIndex;
      minY = maxY - this.maxBarsToShow + 1;
    }

    this.dispatchEvent(
      new CustomEvent("chartscroll", {
        detail: {
          minY,
          maxY
        }
      })
    );
  }
}