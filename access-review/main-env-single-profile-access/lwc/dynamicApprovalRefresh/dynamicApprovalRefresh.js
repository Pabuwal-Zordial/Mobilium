import { LightningElement, api } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { RefreshEvent } from 'lightning/refresh';

const CHANNEL = '/event/Dynamic_Approval_Status__e';

export default class DynamicApprovalRefresh extends LightningElement {
    @api recordId;
    _subscription = null;

    connectedCallback() {
        subscribe(CHANNEL, -1, (event) => {
            const eventRecordId = event?.data?.payload?.Record_Id__c;
            if (eventRecordId === this.recordId) {
                // Refreshes LDS-wired fields...
                getRecordNotifyChange([{ recordId: this.recordId }]);
                // ...and standard related lists (Approval History, Process Instances, etc.)
                // which don't respond to getRecordNotifyChange since they aren't LDS-backed.
                this.dispatchEvent(new RefreshEvent());
            }
        }).then((sub) => {
            this._subscription = sub;
        }).catch((error) => {
            // eslint-disable-next-line no-console
            console.error('DynamicApprovalRefresh: empApi subscribe failed', error);
        });
    }

    disconnectedCallback() {
        if (this._subscription) {
            unsubscribe(this._subscription, () => {});
        }
    }
}