import { LightningElement, api } from 'lwc';

export default class ItemsToApproveCommentsModal extends LightningElement {
	@api title
	@api currentAction;
	comments
	isLoading = false;
	selectedUserId;

	get isReassign() {
		return this.currentAction === 'Reassign';
	}

	@api handleClose() {
		this.hide();
	}

	@api show() {
		this.template.querySelector('c-modal').show();
	}

	@api hide() {
		this.template.querySelector('c-modal').hide();
		this.isLoading = false;
	}

	handlePositiveButtonClick() {
		this.template.querySelector('c-modal').startLoading();
		this.isLoading = true;
		this.dispatchEvent(new CustomEvent('confirm', { 
				detail: {
					data: { 
						comments: this.comments,
						userId: this.selectedUserId
					}
				}
			}));
	}
	selectedUserId

	handleCommentsChange(event) {
		this.comments = event.detail.value;
	}

	handleLookupChange(event) {
		this.selectedUserId = event.detail.data.value;
	}
}