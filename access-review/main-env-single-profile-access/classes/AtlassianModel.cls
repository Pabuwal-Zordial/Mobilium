public with sharing class AtlassianModel
{
	public class Space
	{
		public String id { get; set; }
		public String key { get; set; }
		public String name { get; set; }
		public Map<String, User> keyUsers { get; set; }
		public String projectDirector { get; set; }
		public String projectManager { get; set; }
		public String category { get; set; }
		public String spaceTemplateKey { get; set; }
		public String spaceTemplateTitle { get; set; }
		public String spacePageRestrictionTitle { get; set; }
		public Map<String, String> data { get; set; }
		public Project project { get; set; }
	}

	public class Project
	{
		public String eid { get; set; }
		public String name { get; set; }
		public String acronym { get; set; }
		public String projectTemplateName { get; set; }
		public Map<String, User> keyUsers { get; set; }
	}

	public class User
	{
		public String name { get; set; }
		public String username { get; set; }
	}
}