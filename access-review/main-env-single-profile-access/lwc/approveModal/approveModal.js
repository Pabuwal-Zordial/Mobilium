import { api } from 'lwc';
import LightningModal from 'lightning/modal';
import { updateRecord } from 'lightning/uiRecordApi';

export default class ApproveModal extends LightningModal {
    @api recordId;
    comments = '';
    isLoading = false;
    errorMessage = '';

    handleCommentChange(event) {
        this.comments = event.target.value;
    }

    handleApprove() {
        this.isLoading = true;
        this.errorMessage = '';
        updateRecord({
            fields: {
                Id: this.recordId,
                Status__c: 'Approved',
                Comments__c: this.comments
            }
        })
        .then(() => {
            this.close({ success: true });
        })
        .catch(error => {
            this.errorMessage = error.body ? error.body.message : error.message;
            this.isLoading = false;
        });
    }

    handleCancel() {
        this.close();
    }
}