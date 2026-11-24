public class contacts {
    public static void main(string accountname)
    {
        if(accountname != null && accountname != '')
        {
        string query = 'select id,name from account__c ';
            {
            /*id accountrecordid = lstacc.get(0).id;
            list<contact> con = [select id,name from contact where accountid !=: accountrecordid ];*/
            if(pattern.matches('^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$', accountname))
            {
                system.debug('format is email');
                query += ' where Email_ID__c =: accountname';
                system.debug(query);
                
            }
                else
                {
                   system.debug('stirng');
                    accountname += '%';
                   query += 'where First_Name__c like : accountname';
                    system.debug(query);
                }
               list<account__c> acc = database.query(query);
                system.debug(acc.size());
                if(acc != null)
                {
                    for(account__c aac1 : acc)
                        system.debug(aac1);
                }
                else
                    system.debug('no records');
                    
                
               }
            }
        }
    }