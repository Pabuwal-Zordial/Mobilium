import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class FlowToastNotification extends LightningElement {
    @api message;
    @api toastTitle;
    @api variant; // success | error | warning | info

    connectedCallback() {
        this.dispatchEvent(new ShowToastEvent({
            title   : this.toastTitle || '',
            message : this.message    || '',
            variant : this.variant    || 'info',
            mode    : 'dismissable'
        }));

        this.dispatchEvent(new CloseActionScreenEvent());
    }
}