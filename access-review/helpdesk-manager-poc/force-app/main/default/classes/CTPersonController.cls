public with sharing class CTPersonController {

  public static string getToken(string mobileNumber)
  {
    Blob targetBlob = Blob.valueOf(mobileNumber);
    Blob hash = Crypto.generateDigest('MD5', targetBlob);
    String result = EncodingUtil.base64Encode(hash);
   return result;
  }
  public static List<person__c> GetRecentHealthChanges ()
  {
    List<person__c> getPer = [select id, name, health_status__C , mobile__C , Status_Update_Date__c, token__C from person__c
    ORDER BY Status_Update_Date__c DESC NULLS LAST
                              limit 100 ];

                              return getPer;
  }
  public static List<person__c> searchPeople (string searchTerm)
  {
     searchTerm = searchTerm + '%';
    List<person__c> getPer1 = [select id, name, health_status__C , mobile__C , Status_Update_Date__c, token__C from person__c where name like : searchTerm or Mobile__c like : searchTerm
                              or Token__c like : searchTerm
                            
                              limit 100 ];

                              return getPer1;

  }

  public static person__c getPersonById(String PersonID)
  {
    list<person__c> person = [select id, name, health_status__C , mobile__C , Status_Update_Date__c, token__C from person__c WHERE
              name =: personid ];

    if(person != null || person.size() > 0)
    {
      return person[0];
    }
    else {
      return null;
    }
  }

  public static map<string,Integer> getHealthStatusCount()
  {
    map<string,Integer> map1 = new map<string,Integer>();
    for(aggregateResult[] agg : [select COUNT(id) cou, health_status__C from person__c GROUP BY health_status__C])
    {
      map1.put(string.valueof(agg[0].get('health_status__C')),Integer.valueof(agg[0].get('cou')));
    }
    return map1;
    
  }
     
}