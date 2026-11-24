public class DeduplicateApprovers {

    @InvocableMethod(label='Remove Duplicate Approvers')
    public static List<List<String>> removeDuplicates(List<List<String>> inputList){

        Set<String> uniqueIds = new Set<String>();

        for(List<String> ids : inputList){

            uniqueIds.addAll(ids);
        }

        return new List<List<String>>{
            new List<String>(uniqueIds)
        };
    }
}