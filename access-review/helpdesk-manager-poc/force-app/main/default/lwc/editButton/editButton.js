import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import hideInlineEdit from '@salesforce/resourceUrl/hideInlineEdit';

export default class EditButton extends LightningElement {
    styleElement;

    connectedCallback() {
        loadStyle(this, hideInlineEdit)
            .then(() => {
                this.styleElement = this.template.querySelector('style');
            })
            .catch(error => {
                console.error('Error loading CSS', error);
            });
    }

    disconnectedCallback() {
        if (this.styleElement) {
            this.styleElement.remove();
            this.styleElement = undefined;
        }
    }
}