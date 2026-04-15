import { LightningElement,api } from 'lwc';

export default class Ecom_paginator extends LightningElement {
    _totalRecords;
    @api
    set totalRecords(val){
        this._totalRecords = val;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
    }

    get totalRecords(){
        return this._totalRecords;
    }
    @api currentPageNumber;
    @api pageSize ;
    maximumPagesDisplayed = 3;
    totalPages;
    connectedCallback() {
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
    }
    disablePreviousPageNavigation() {
        return 1 === this.currentPageNumber;
    }
    disableNextPageNavigation() {
        return this.currentPageNumber >= this.totalPages;
    }
    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    // RWPS-3826 start
    handleEnterPress(event) {
        if (event.key === 'Enter' || event.keyCode === 13 || event.key === 'Space' || event.keyCode === 32) { // RWPS-4086
            event.target.click();
        }
    }
    // RWPS-3826 end

    get pageNumbers() {
        let current = this.currentPageNumber,
            last = this.totalPages,
            delta = 1,
            left = current - delta,
            right = current + delta + 1,
            range = [],
            pages = [],
            l;
        for (let i = 1; i <= last; i++) {
            if (i == 1 || i == last || i >= left && i < right) {
                range.push(i);
            }
        }
        let counter = 0;
        for (let i of range) {
            let pageData = {};
            if (l) {
                if (i - l === 2) {
                    pageData.pageNumber= l + 1;
                    pageData.isRange = false;
                    pageData.isPage = true;
                    pageData.id = counter;
                    pageData.isCurrentPage = current === l + 1 ?true:false;
                    if( pageData.isCurrentPage){
                        pageData.classNames = 'pagenumber active';
                    }else{
                        pageData.classNames = 'pagenumber';
                    }
                    pages.push(pageData);
                    counter++;
                } else if (i - l !== 1) {
                    pageData.pageNumber = '...' ;
                    pageData.isRange = true;
                    pageData.isPage = false;
                    pageData.id = counter;
                    pageData.classNames = 'pagenumber';
                    pageData.isCurrentPage =false;
                    pages.push(pageData);
                    counter++;
                }
            }
            pageData = {}
            pageData.pageNumber = i ;
            pageData.isRange = false;
            pageData.isPage = true;
            pageData.id = counter;
            pageData.isCurrentPage = current === i ?true:false;
            if( pageData.isCurrentPage){
                pageData.classNames = 'pagenumber active';
            }else{
                pageData.classNames = 'pagenumber';
            }
            pages.push(pageData);
            counter++;
            l = i;
        }
        return pages;
    }

    handleGoToPage(e){
            this.dispatchEvent(new CustomEvent('gotopage', {
                detail: {
                    pageNumber : e.currentTarget.dataset.page
                }
            }));
    }
    handlePreviousPage(e){
            let currentPage = parseInt(this.currentPageNumber);
            if(!this.disablePreviousPageNavigation()){
                this.dispatchEvent(new CustomEvent('gotopage', {
                    detail: {
                        pageNumber : (currentPage-1)
                    }
                }));
            }
    }
    handleNextPage(e){
        let currentPage = parseInt(this.currentPageNumber);
        if(!this.disableNextPageNavigation()){
            this.dispatchEvent(new CustomEvent('gotopage', {
                detail: {
                    pageNumber : (currentPage+1)
                }
            }));
        }
    }
    goToLast(){
        if(!this.disableNextPageNavigation()){
            this.dispatchEvent(new CustomEvent('gotopage', {
                detail: {
                    pageNumber : this.totalPages
                }
            }));
        }
    }

    goToFirst(){
        if(!this.disablePreviousPageNavigation()){
            this.dispatchEvent(new CustomEvent('gotopage', {
                detail: {
                    pageNumber : 1
                }
            }));
        }
    }
}