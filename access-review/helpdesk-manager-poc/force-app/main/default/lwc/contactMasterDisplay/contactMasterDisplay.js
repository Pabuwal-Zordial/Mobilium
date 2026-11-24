import { LightningElement, wire } from 'lwc';
import fetchAllContacts from '@salesforce/apex/ContactManager.fetchAllContacts';
import fetchAccount from '@salesforce/apex/ContactManager.fetchAccount';
import { NavigationMixin } from 'lightning/navigation';
export default class ContactMasterDisplay extends NavigationMixin(LightningElement) {
  accountOptions=[];
  errorDetails;
  selectedAccount;
    @wire(fetchAccount)
    accountProcess({error,data})
    {
      if(data){
        this.errorDetails=undefined;
        for(var i=0;i<data.length;i++)
        {
          this.accountOptions = [...this.accountOptions,{value:data[i].Id,label:data[i].Name}];
        }
      }
      else if(error)
      {
        this.data=undefined;
      }
    }

    handleAccountChange(event){
      this.selectedAccount=event.detail.value;
    }

   
    @wire(fetchAllContacts,{accId:'$selectedAccount'})
    contacts;
    contactId;
    NavigateToRecord(event){
      this.contactId=event.target.value;
    
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId:this.contactId,
                objectApiName:'Contact',
                actionName: 'view'
                }
                });

    }
    get accounts1() {
      return accounts;
  }
    handleChange(event)
    {
      this.accountName=event.target.value;
    }

}