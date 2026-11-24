public with sharing class AtlassianConstants
{
	public static final Set<String> KEY_USERS_NAME = new Set<String> { 'project-director', 'project-manager' };

	public static final String PERMISSION_TYPE_USER = 'user';
	public static final String PERMISSION_TYPE_GROUP = 'group';

	public static final String GENERAL_PERMISSION_VIEW = 'view';
	public static final String GENERAL_PERMISSION_READ = 'read';
	public static final String GENERAL_PERMISSION_UPDATE = 'update';

	public static final String SPACE_PERMISSION_VIEW = 'VIEWSPACE';
	public static final String SPACE_PERMISSION_EDIT = 'EDITSPACE';
	public static final String SPACE_PERMISSION_SET_PAGE = 'SETPAGEPERMISSIONS';
	public static final String SPACE_PERMISSION_REMOVE_PAGE = 'REMOVEPAGE';
	public static final String SPACE_PERMISSION_EDIT_BLOG = 'EDITBLOG';
	public static final String SPACE_PERMISSION_REMOVE_BLOG = 'REMOVEBLOG';
	public static final String SPACE_PERMISSION_COMMENT = 'COMMENT';
	public static final String SPACE_PERMISSION_REMOVE_COMMENT = 'REMOVECOMMENT';
	public static final String SPACE_PERMISSION_CREATE_ATTACHMENT = 'CREATEATTACHMENT';
	public static final String SPACE_PERMISSION_REMOVE_ATTACHMENT = 'REMOVEATTACHMENT';
	public static final String SPACE_PERMISSION_REMOVE_EMAIL = 'REMOVEMAIL';
	public static final String SPACE_PERMISSION_REMOVE_OWN_CONTENT = 'REMOVEOWNCONTENT';
	public static final String SPACE_PERMISSION_EXPORT_SPACE = 'EXPORTSPACE';

	public static final String CONFLUENCE_SPACE_CATEGORY_CUSTOMER = 'customer';
	public static final String CONFLUENCE_SPACE_CATEGORY_PROJECT = 'project';
	public static final String CONFLUENCE_PAGE_PERMISSION_TITLE = 'Project Deliverables Map';
	public static final String CONFLUENCE_PSO_PAGE_TITLE = 'Project Support Office';

	public static final String JIRA_ASSIGNEE_TYPE = 'PROJECT_LEAD';
	public static final String JIRA_UNASSIGNED_TYPE = 'UNASSIGNED';
	public static final Integer JIRA_AVATAR_ID = 10200;
	public static final Integer JIRA_CATEGORY_ID = 10002;
	public static final Integer JIRA_ISSUE_SECURITY_SCHEME = 10001;
	public static final Integer JIRA_NOTIFICATION_SCHEME = 10000;
	public static final Integer JIRA_PERMISSION_SCHEME = 0;
	public static final String JIRA_PROJECT_TEMPLATE_KEY = 'com.pyxis.greenhopper.jira:basic-software-development-template';
	public static final String JIRA_PROJECT_TYPE_KEY = 'software';
	public static final String JIRA_ADMIN_ROLE = '10002';
	public static final String JIRA_MANAGER_ROLE = '10500';

	public static final List<String> PAGE_PERMISSIONS = new List<String>
	{
		'read',
		'update'
	};
	public static final List<String> SPACE_PERMISSIONS = new List<String>
	{
		'VIEWSPACE',
		'EDITSPACE',
		'REMOVEOWNCONTENT',
		'SETPAGEPERMISSIONS',
		'REMOVEPAGE',
		'EDITBLOG',
		'REMOVEBLOG',
		'COMMENT',
		'REMOVECOMMENT',
		'CREATEATTACHMENT',
		'REMOVEATTACHMENT',
		'REMOVEMAIL',
		'EXPORTSPACE',
		'SETSPACEPERMISSIONS'
	};
}