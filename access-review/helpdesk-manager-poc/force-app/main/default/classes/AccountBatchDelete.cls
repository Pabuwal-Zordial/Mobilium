public class AccountBatchDelete {
    
    @future
   public static void main(set<id> accids)
   {
       list<account> accids1 = [select id from account where id in :accids and name like 'acc%' order by createddate desc limit 20];
   if(!accids1.isEmpty())
   {
       try{
       delete accids1;
        
          task tsk = new task();
           tsk.subject = 'records future deleted';
           tsk.OwnerId = '0052w000002r3qIAAQ';
           tsk.Description = accids1 + 'records ids' + 'deleted by' + tsk.CreatedById;
           insert tsk;
           system.debug(tsk.id);
              
       }
       catch(exception e){
           system.debug( e);
           
       }
   }
   }
}