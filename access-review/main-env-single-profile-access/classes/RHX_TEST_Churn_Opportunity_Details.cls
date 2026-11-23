@isTest(SeeAllData=true)
public class RHX_TEST_Churn_Opportunity_Details {
 static testMethod void RHX_Testmethod() {
        List<sObject> sourceList = [SELECT Id 
                   FROM Churn_Opportunity_Details__c ORDER BY LastModifiedDate DESC LIMIT 1];
        if(sourceList.size() == 0) {
            sourceList.add(
                    new Churn_Opportunity_Details__c()
            );
        }
      

       rh2.ParentUtil.UpsertRollupTestRecords( sourceList );
    }
}