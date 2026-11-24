public with sharing class ConfluenceRequest
{
	public class Space
	{
		public String id { get; set; }
		public String key { get; set; }
		public String name { get; set; }
		public String type { get; set; }

		public Space()
		{
			this.type = 'global';
		}
	}

	public class SpacePermission
	{
		public List<String> permissions { get; set; }
		public String userOrGroup { get; set; }
		public String spaceKey { get; set; }
	}

	public class SpacePage
	{
		public String id { get; set; }
		public String type { get; set; }
		public String title { get; set; }
		public Space space { get; set; }
		public SpacePageBody body { get; set; }
		public SpacePageExtensions extensions { get; set; }
		public Object version { get; set; }
		public List<SpacePage> ancestors { get; set; }

		public SpacePage()
		{
			this.type = 'page';
		}
	}

	public class SpacePageBody
	{
		public SpacePageStorage storage { get; set; }
	}

	public class SpacePageStorage
	{
		public String value { get; set; }
		public String representation { get; set; }

		public SpacePageStorage()
		{
			this.representation = 'storage';
		}
	}

	public class SpacePageExtensions
	{
		public String position { get; set; }
	}

	public class SpacePagePermission
	{
		public String pageId { get; set; }
		public String permission { get; set; }
		public String type { get; set; }
		public String userOrGroup { get; set; }
	}
}