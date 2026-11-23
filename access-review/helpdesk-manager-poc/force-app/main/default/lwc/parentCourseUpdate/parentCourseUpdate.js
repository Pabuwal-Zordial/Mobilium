import { LightningElement, api } from 'lwc';

export default class ParentCourseUpdate extends LightningElement {
    @api pcourseName='Aura';
    @api pcourseFee='1000';
    
    parentUpdateFee(){
        this.template.querySelector('c-course-detail-update').updateFee();
    }
}