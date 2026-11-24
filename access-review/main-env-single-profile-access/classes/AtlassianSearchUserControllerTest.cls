@IsTest
private class AtlassianSearchUserControllerTest
{
	@TestSetup
	static void setup()
	{
		Atlassian_Configs__c configs = new Atlassian_Configs__c
		(
			SetupOwnerId = UserInfo.getOrganizationId(),
			Emails_To_Notify__c = 'john.doe@mail.com',
			Confluence_Base_URL__c = 'https://www.confluence.com/base/',
			Confluence_Experimental_Base_URL__c = 'https://www.confluence.com/expbase/',
			Confluence_RPC_Base_URL__c = 'https://www.confluence.com/rpcbase/',
			CustomerEidPageSpaceTemplateKey__c = 'customer_eid_page_space_template_key',
			CustomerEidPageSpaceTemplatePageTitle__c = 'customer_eid_page_space_template_page_title',
			CustomerSpaceTemplateKey__c = 'customer_space_template_key',
			CustomerSpaceTemplatePageTitle__c = 'customer_space_template_page_title',
			EidSpaceTemplateKey__c = 'eid_space_template_key',
			EidSpaceTemplatePageTitle__c = 'eid_space_template_title',
			ProjectTemplateKey__c = 'project_template_key',
			Token__c = '12345aaaa',
			Jira_Base_URL__c = 'https://www.jira.com/base/'
		);
		insert configs;
	}

	@IsTest
	private static void testSuccessfulSearch()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Test.startTest();
		List<JiraResponse.JiraUser> response = AtlassianSearchUserController.searchUsers('test');
		Test.stopTest();

		System.assertEquals(1, response.size());
		JiraResponse.JiraUser jiraUser = response[0];
		System.assertEquals('test', jiraUser.key);
		System.assertEquals('test', jiraUser.name);
		System.assertEquals('test', jiraUser.displayName);
		System.assertEquals('test@test.com', jiraUser.emailAddress);
	}

	@IsTest
	private static void testUnsuccessfulSearch()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Test.startTest();
		Exception ex;
		try
		{
			List<JiraResponse.JiraUser> response = AtlassianSearchUserController.searchUsers('fail');
		}
		catch (Exception e)
		{
			ex = e;
		}

		Test.stopTest();

		System.assertEquals(true, ex <> null);
	}
}