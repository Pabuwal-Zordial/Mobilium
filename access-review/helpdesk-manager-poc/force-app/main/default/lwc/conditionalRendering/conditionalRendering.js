import { LightningElement, track } from 'lwc';
export default class ConditionalRendering extends LightningElement {
@track displayDiv = false;
@track divChange;
@track cityList = ['Jaipur', 'bangalore', 'Mumbai', 'kmk'];
 
divChangeHandler(event)
{
    this.displayDiv = event.target.checked;
    this.divChange = event.target.event;
}
}