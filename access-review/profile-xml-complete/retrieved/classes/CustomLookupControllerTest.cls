@IsTest
public class CustomLookupControllerTest {
	@isTest
	public static void searchTest(){
		User user = [SELECT Id, Name FROM User LIMIT 1];
		Test.startTest();
			List<LookupSearchResult> results = CustomLookupController.search(user.Name, 'User');
		Test.stopTest();
		System.assert(!results.isEmpty());

		LookupSearchResult searchedUserResult;
		for(LookupSearchResult result: results) {
			if (result.getId() == user.Id) {
				searchedUserResult = result;
			}
		}
		System.assert(searchedUserResult != null);
		System.assertEquals(searchedUserResult.getSObjectType(), 'User');
		System.assertEquals(searchedUserResult.getIcon(), null);
		System.assertEquals(searchedUserResult.getTitle(), user.Name);
		System.assertEquals(searchedUserResult.getSubtitle(), null);
	}
}