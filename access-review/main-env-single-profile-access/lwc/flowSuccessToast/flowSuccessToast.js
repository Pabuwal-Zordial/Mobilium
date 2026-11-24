import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class FlowSuccessToast extends LightningElement {
    @api message = 'Approval Submitted Successfully';
    _fired = false;

    renderedCallback() {
        if (this._fired) return;
        this._fired = true;

        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: this.message,
            variant: 'success'
        }));

        this.dispatchEvent(new FlowNavigationFinishEvent());
    }
}