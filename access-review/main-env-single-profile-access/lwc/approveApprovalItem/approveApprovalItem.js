import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ApproveModal from 'c/approveModal';

export default class ApproveApprovalItem extends NavigationMixin(LightningElement) {
    @api recordId;

    @api invoke() {
        return ApproveModal.open({
            size: 'medium',
            recordId: this.recordId
        }).then(result => {
            if (result && result.success) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Approved',
                    message: 'Request approved successfully.',
                    variant: 'success'
                }));
            }
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: this.recordId, actionName: 'view' }
            });
        });
    }
}