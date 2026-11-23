import { LightningElement } from 'lwc';

export default class Calender extends LightningElement {



  monthVal;
  selDate;

  handleDate(event){
    let dt = event.target.value;
    this.selDate = dt;
    this.monthVal = new Date(dt).getMonth();
  }
}