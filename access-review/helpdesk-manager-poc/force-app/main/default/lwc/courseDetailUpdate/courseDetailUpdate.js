import { LightningElement, api } from 'lwc';

export default class CourseDetailUpdate extends LightningElement {
    @api courseName='Lighting';
    @api courseFee='10000';
  @api
  updateFee(){
        this.courseFee = parseFloat(this.courseFee)*2;
}
changeCourseFee(event){
    this.coursefee = event.target.value;
}

}