global class StudentSoapService
{
    webService static Student__c getStudentById(String stdId)
    {
       Student__c student=[select id,name from Student__c where id=: stdId];
      return student;
    }

}