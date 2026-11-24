import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import RejectModal from 'c/rejectModal';

export default class RejectApprovalItem extends NavigationMixin(LightningElement) {
    @api recordId;

    @api invoke() {
        return RejectModal.open({
            size: 'medium',
            recordId: this.recordId
        }).then(result => {
            if (result && result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Rejected',
                    message: 'Request has been rejected.',
                    variant: 'warning'
                }));
            }
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: this.recordId, actionName: 'view' }
            });
        });
    }
}