import { wire, api, track } from 'lwc';
import ItemsToApprove from 'c/itemsToApprove';
import getPendingForApprovalRecords from '@salesforce/apex/ItemsToApproveController.getPendingForApprovalRecords';

const columns = [
	{ label : 'Name', fieldName : 'relatedToLink', type : 'url', typeAttributes : { label: { fieldName: 'recordName' }, target:'_blank'}, sortable : true },
	{ label : 'Related to', fieldName : 'relatedTo', type : 'text', sortable : true },
	{ label : 'Submitted by', fieldName : 'submittedBy', type : 'text', sortable : true },
	{ label : 'Submitted date', fieldName : 'submittedDate', type : 'date', typeAttributes : { year: "numeric", month:"numeric", day: "numeric" }, sortable : true }
]

export default class ItemsToApproveTable extends ItemsToApprove {
	@api fieldToOrderData;
	@api sObjectApiName;
	@api sObjectFieldsJson;

	@track sortBy;
	@track sortDirection;

	relatedTofieldsToQuery = [];

	connectedCallback() {
		this.columns = columns;

		this.sObjectFieldsJson = JSON.parse(this.sObjectFieldsJson);
		this.sObjectFieldsJson.forEach(column => {
			this.relatedTofieldsToQuery.push(column.fieldName);
		})

		this.columns = this.columns.concat(this.sObjectFieldsJson);

		this.columns.push({
			type: 'action',
			typeAttributes: { rowActions: this.actions }
		});
	}

	@wire(getPendingForApprovalRecords, { sObjectApiName: '$sObjectApiName', relatedObjectFields: '$relatedTofieldsToQuery', orderByFieldName: '$fieldToOrderData' })
	wiredAccount(result) {
		this.pendingForApprovalRecordsWired = result;
		if (result.data && result.data.length > 0) {
			this.pendingForApprovalRecords = [];
			result.data.forEach(element => {
				let tempElement = this.setupElement(element);
				this.relatedTofieldsToQuery.forEach(extraField => {
					tempElement[extraField] = element.relatedToObjectFieldsData[extraField];
				});
				this.pendingForApprovalRecords.push(tempElement);
			});
			this.isLoading = false;
		} else if (result.error) {
			this.isLoading = false;
			console.log('getPendingForApprovalRecords ERROR -> ' , result.error);
			this.showToast('Error retrieving pending for approval ' + this.sObjectApiName + ' records', result.error, 'error');
			this.pendingForApprovalRecords = undefined;
		}
	}

	handleRowAction(event) {
		const workItemId = event.detail.row.workItemId;
		const currentAction =  event.detail.action.value;
		this.showCommentsModal(currentAction, workItemId);
	}

	doSorting(event) {
		this.sortBy = event.detail.fieldName;
		this.sortDirection = event.detail.sortDirection;
		this.sortData(this.sortBy, this.sortDirection);
	}

	sortData(fieldname, direction) {
		let parseData = JSON.parse(JSON.stringify(this.pendingForApprovalRecords));
		// Return the value stored in the field
		let keyValue = (a) => {
			return a[fieldname];
		};
		// cheking reverse direction
		let isReverse = direction === 'asc' ? 1: -1;
		// sorting data
		parseData.sort((x, y) => {
			x = keyValue(x) ? keyValue(x) : ''; // handling null values
			y = keyValue(y) ? keyValue(y) : '';
			// sorting values based on direction
			return isReverse * ((x > y) - (y > x));
		});
		this.pendingForApprovalRecords = parseData;
	}
}