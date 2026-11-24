public class practise1 {
	Public Static Void Main()
{
    /*list<Integer> list1 = new list<Integer>{1,2,3,4};
        list<Integer> list2 = new list<Integer>{2,5,6,7};
             list<Integer> list3 = new list<Integer>{8,2,9,0};
                 list<integer> list4 = new list<integer>();
                 list4.addAll(list1);
     list4.addAll(list2);
     list4.addAll(list3);
    

    system.debug('>>>>>'+ list1);
     system.debug('>>>>>'+ list2);
     system.debug('>>>>>'+ list3);
    system.debug('>>>>>'+ list4);
    
    
set<Integer> set1 = new set<Integer>();
set1.addall(list4);
    //set1.addall(list2);
    //set1.addall(list3);
    
    system.debug(set1);*/
    List<String> listA = new List<String> { 'A', 'B', 'C', 'D'};
List<String> listB = new List<String> { 'A', 'E', 'C', 'F'};

/*SETs will only hold unique elements. Thus the [].addAll() will eliminate duplicates automatically if found.*/    
Set<String> setUnion = new Set<String>();
setUnion.addAll(listA);
setUnion.addAll(listB);

/*Add the UNIONed Set back to a List Collection*/
List<String> listUnion = new List<String>();
listUnion.addAll(setUnion);

/*Sorting if needed*/
listUnion.sort();

System.debug(listUnion);

}

}