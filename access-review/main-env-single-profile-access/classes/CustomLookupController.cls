public with sharing class CustomLookupController
{
	@AuraEnabled(Cacheable=true)
	public static List<LookupSearchResult> search(String searchTerm, String objectType)
	{		
		List<LookupSearchResult> searchResults = new List<LookupSearchResult>();
		searchTerm = '%' + searchTerm + '%';

		String queryString = String.format('SELECT Id, Name FROM {0} WHERE Name LIKE {1} LIMIT 10', new List<String> {
			objectType,
			'\'' + searchTerm + '\''
		});

		for(SObject searchObject : Database.query(queryString))
		{
			LookupSearchResult searchResult = new LookupSearchResult(
				searchObject.Id,
				objectType,
				null,
				(String)searchObject.get('Name'),
				null
			);
			searchResults.add(searchResult);
		}

		return searchResults;
	}
}