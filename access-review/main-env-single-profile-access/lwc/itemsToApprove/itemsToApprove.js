import { LightningElement, track } from 'lwc';
import { ShowToastEvent, } from 'lightning/platformShowToastEvent';
import processRecords from '@salesforce/apex/ItemsToApproveController.processRecords';
import { refreshApex } from '@salesforce/apex';

export default class ItemsToApprove extends LightningElement {
	@track modalTitle;

	selectedWorkItemId;
	currentAction;

	pendingForApprovalRecordsWired
	pendingForApprovalRecords

	@track actions = [
		{ label: 'Approve', value: 'Approve' },
		{ label: 'Reject', value: 'Reject' },
		{ label: 'Reassign', value: 'Reassign' }
	];

	showToast(title, message, variant) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(event);
	}

	setupElement(element) {
		const copiedElement = {... element}
		copiedElement.relatedToLink = '/' + element.recordId;
		copiedElement.tileOverviewText = element.relatedTo + ' - Submitted by ' + element.submittedBy;
		return copiedElement;
	}

	callProcessRecords(workItemActions) {
		processRecords({workItemActions: workItemActions })
			.then(() => {
				this.showToast('Success', 'Record ' + this.getSuccessActionVerb() + ' successfully', 'success');
				this.template.querySelector('c-items-to-approve-comments-modal').hide();
				this.refreshData();
			})
			.catch(error => {
				this.showToast('Error', 'Error while ' + this.getErrorActionVerb() + ' the record', 'error');
				this.template.querySelector('c-items-to-approve-comments-modal').hide();
				this.refreshData();
			});
	}

	getSuccessActionVerb() {
		if (this.currentAction === 'Approve') {
			return 'approved';
		} else if (this.currentAction === 'Reject') {
			return 'rejected';
		} else if (this.currentAction === 'Reassign') {
			return 'reassigned'; Reassign
		}
		return '';
	}

	getErrorActionVerb() {
		if (this.currentAction === 'Approve') {
			return 'approving';
		} else if (this.currentAction === 'Reject') {
			return 'rejecting';
		} else if (this.currentAction === 'Reassign') {
			return 'reassigning'; Reassign
		}
		return '';
	}

	showCommentsModal(currentAction, workItemId) {
		this.selectedWorkItemId = workItemId;
		this.currentAction = currentAction;

		this.modalTitle = currentAction + ' ' + this.pendingForApprovalRecords.find(element => element.workItemId === workItemId).relatedToLabel;

		this.template.querySelector('c-items-to-approve-comments-modal').show();
	}

	refreshData() {
		refreshApex(this.pendingForApprovalRecordsWired);
	}

	handleConfirmModal(event) {
		const comments = event.detail.data.comments;
		const userId = event.detail.data.userId;

		const currentRecord = this.pendingForApprovalRecords.find(element => element.workItemId === this.selectedWorkItemId);
		let workItemAction = {workItemId: this.selectedWorkItemId, type: this.currentAction, comments: comments, recordId: currentRecord.recordId, processInstanceId: currentRecord.processInstanceId}

		if (this.currentAction === 'Reassign') {
			workItemAction.newActorId = userId;
		}
		
		let workItemActions = new Array(workItemAction);

		this.callProcessRecords(workItemActions);
	}

	handleCloseModal() {
		this.clearActionVariables();
	}

	clearActionVariables() {
		this.selectedWorkItemId = undefined;
		this.currentAction = undefined;
	}
}