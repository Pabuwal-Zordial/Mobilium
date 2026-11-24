public with sharing class ConfluenceResponse
{
	public static Space getSpaceObject(String jsonString)
	{
		jsonString = jsonString.replace('"_links"', '"links"');
		return (Space) JSON.deserialize(jsonString, Space.class);
	}

	public class Space
	{
		@AuraEnabled public Integer id { get; set; }
		@AuraEnabled public String key { get; set; }
		@AuraEnabled public String name { get; set; }
		@AuraEnabled public Content homepage { get; set; }
		@AuraEnabled public Map<String, String> links { get; set; }
	}

	public static ContentArray getContentArrayObject(String jsonString)
	{
		jsonString = jsonString.replace('"number"', '"versionNumber"');
		return (ContentArray) JSON.deserialize(jsonString, ContentArray.class);
	}

	public static Content getContentObject(String jsonString)
	{
		jsonString = jsonString.replace('"_links"', '"links"');
		return (Content) JSON.deserialize(jsonString, Content.class);
	}

	public static SpacePages getSpacePagesObject(String jsonString)
	{
		jsonString = jsonString.replace('"_links"', '"links"');
		jsonString = jsonString.replace('"page"', '"response"');
		return (SpacePages) JSON.deserialize(jsonString, SpacePages.class);
	}

	public class SpacePages
	{
		@AuraEnabled public ContentArray response { get; set; }
	}

	public class ContentArray
	{
		@AuraEnabled public List<Content> results { get; set; }
	}

	public class Content
	{
		@AuraEnabled public String id { get; set; }
		@AuraEnabled public String title { get; set; }
		@AuraEnabled public String type { get; set; }
		@AuraEnabled public ContentBody body { get; set; }
		@AuraEnabled public ContentExtensions extensions { get; set; }
		@AuraEnabled public Space space { get; set; }
		@AuraEnabled public List<Content> ancestors { get; set; }
		@AuraEnabled public Map<String, String> links { get; set; }
		@AuraEnabled public ContentPageVersion version { get; set; }
	}

	public class ContentBody
	{
		@AuraEnabled public Storage storage { get; set; }
	}

	public class ContentPageVersion
	{
		@AuraEnabled public Integer versionNumber { get; set; }
	}

	public class Storage
	{
		@AuraEnabled public String representation { get; set; }
		@AuraEnabled public String value { get; set; }
	}

	public class ContentExtensions
	{
		@AuraEnabled public String position { get; set; }
	}
}