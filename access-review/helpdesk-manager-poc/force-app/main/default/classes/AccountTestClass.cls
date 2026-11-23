@isTest
public class AccountTestClass {
    static TestMethod void InsertContact(){
        Account Accobj = new Account();
        Accobj.name = 'Test';
        Accobj.Rating = 'Hot';
        insert Accobj;      
    }

}