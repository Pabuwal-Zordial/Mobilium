import { LightningElement, wire } from 'lwc';
import  getBranch from '@salesforce/apex/GetBranches.GetBranch';
import  GetBank from '@salesforce/apex/GetBranches.GetBank';

export default class BranchesBank extends LightningElement {
    selectedBank;
    errorDetails;
    branchOptions=[];
    @wire(GetBank)
    banks({error,data})
    {
        if(data)
        {
            this.errorDetails=undefined;
           for(var i=0;i<data.length;i++)
           {
            this.branchOptions = [...this.branchOptions,{value:data[i].Id,label:data[i].Name}];
           }
        }
        else if(error)
        {
            this.data=undefined;
        }
    }


    handleBranchChange(event){
        this.selectedBank=event.detail.value;
    }

    @wire(getBranch,{bankId:'$selectedBank'})
    branch;
}