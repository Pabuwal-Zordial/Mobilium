import { LightningElement } from 'lwc';

export default class CourseCalci extends LightningElement {
    courseName;
    students;
    courseFee;
    totalFee;
    firstName = '';
    lastName = '';
    showvalue=false;
    showvalue1=false;

    courseValue(event)
    {
        this.courseName = event.target.value;
       
    }
    studentsValue(event)
    {
        this.students = event.target.value;
        if(this.students != null || this.students == '')
        {
        this.showvalue = false;
        }
        else{
            this.showvalue = true; 
            this.totalFee = this.students * this.courseFee;
        }
      
        
    }

    courseFeeValue(event)
    {
        this.courseFee = event.target.value;
        if( this.courseFee == null ||  this.courseFee == '')
        {
            this.showvalue = false;
        }
        else{
            this.showvalue = true;
        this.totalFee = this.students * this.courseFee;

        }
        
      
    }
    handleChange(event)
    { 
        this.firstName = event.target.value;
    }
    get fullName()
    {
        return '${this.firstName} ${this.lastName}'.trim().toUpperCase();
        alert(3);

    }
    /*checkClick(event){
        this.totalFee = this.students * this.courseFee;
        this.showvalue = true;
       
    }*/ 


    allCourseDetails = [
        {courseName:'Lwc', CourseDuration:'20 Days'},
        {courseName:'Lwc1', CourseDuration:'20 Days'},
        {courseName:'Lwc2', CourseDuration:'20 Days'},
        {courseName:'Lw32', CourseDuration:'20 Days'}
    ];
}