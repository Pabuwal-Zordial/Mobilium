public class position {
    public static void main(string bankname)
    {
        if(bankname != null && bankname != '')
        {
            list<Bank__c> bankna = [select id,name from bank__C where name =: bankname];
            id bankid = bankna.get(0).id;
            list<branch__c> lstbranch = [select id,name from branch__c where bank__c =: bankid];
            if(! lstbranch.isEmpty())
            {
                for(branch__c bran : lstbranch )
                    system.debug(bran);
                  
            }
            
        }
    }
}