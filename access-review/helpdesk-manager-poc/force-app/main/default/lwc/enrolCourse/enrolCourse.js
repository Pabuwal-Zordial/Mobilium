import { LightningElement, api } from 'lwc';

export default class EnrolCourse extends LightningElement {

   @api courseDetailInfo={courseName:'lwc', courseDuration:'30 days', coursefee:'10000', courseRating:'*****'};

}