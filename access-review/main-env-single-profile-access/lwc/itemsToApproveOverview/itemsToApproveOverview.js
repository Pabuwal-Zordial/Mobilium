import { api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ItemsToApprove from 'c/itemsToApprove';
import getPendingForApprovalRecords from '@salesforce/apex/ItemsToApproveController.getPendingForApprovalRecords';

export default class itemsToApproveOverview extends NavigationMixin(ItemsToApprove) {
	@api title;
	@api numberOfRecords;
	@api fieldToOrderData;
	@api sObjectApiName;

	@wire(getPendingForApprovalRecords, { sObjectApiName: '$sObjectApiName', orderByFieldName: '$fieldToOrderData' })
	wiredAccount(result) {
		this.pendingForApprovalRecordsWired = result;
		if (result.data && result.data.length > 0) {
			this.pendingForApprovalRecords = [];
			result.data.slice(0, this.numberOfRecords).forEach(element => {
				this.pendingForApprovalRecords.push(this.setupElement(element));
			});
			this.isLoading = false;
		} else if (result.error) {
			this.isLoading = false;
			console.log('getPendingForApprovalRecords ERROR -> ' , result.error);
			this.showToast('Error retrieving pending for approval ' + this.sObjectApiName + ' records', result.error, 'error');
			this.pendingForApprovalRecords = undefined;
		}
	}

	handleTileAction(event) {
		const workItemId = event.target.dataset.id;
		const currentAction = event.detail.action.value;
		this.showCommentsModal(currentAction, workItemId);
	}

	viewAll() {
		window.open('/lightning/n/Pending_Items_to_Approve', '_self');
	}
}