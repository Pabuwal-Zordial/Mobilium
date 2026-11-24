import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NavigateToObjectHome extends NavigationMixin(LightningElement) {

    NavigateToNew(){
        this[NavigationMixin.Navigate]({
            type:'standard__objectPage',
            attributes:{
                objectApiName:'Account',
                actionName:'new'
            },
            state: {
                defaultFieldValues: 'AccountNumber=1234,Name=Debasis,NumberOfEmployees=250,Active__c=yes',
                nooverride: '1'
            }
 
        });
    }
}