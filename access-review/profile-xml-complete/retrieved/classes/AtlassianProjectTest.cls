@isTest
private class AtlassianProjectTest
{
	@testSetup
	private static void setup()
	{
		Account account = new Account(
			Name = 'Test Account'
		);
		insert account;

		Customer_Acronym__c customerAcronym = new Customer_Acronym__c(
			Name = 'TESTCA',
			Atlassian_Key__c = 'TESTCA',
			Final_Customer__c = account.Id
		);
		insert customerAcronym;

		Opportunity opportunity = new Opportunity(
			Name = 'Test Opportunity',
			StageName = 'Pipeline',
			CloseDate = Date.today().addDays(10),
			AccountId = account.Id,
			Customer_Acronym__c = customerAcronym.Id,
			Entity_Number__c = '11 - Roamware, Inc. - US',
			Type = 'POC-Proof of Concept',
			Business_Unit__c = 'Security',
			Total_Security_Forecast_QC__c = 1000
		);
		insert opportunity;

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

		ProposalCodeGeneratorController.generateMasterCode(opportunity.Id);
	}

	@isTest
	private static void testInitData()
	{
		Proposal_Code__c proposalCode = [SELECT Id, Name FROM Proposal_Code__c];

		Test.startTest();
		ProjectUtils.Response response = ProjectController.initData(proposalCode.Id);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
		ProjectController.IntegrationContext context =  (ProjectController.IntegrationContext) response.value;
		System.assertEquals(false, context.projectRecord.Id <> null);
		System.assertEquals(proposalCode.Name, context.eid);
	}

	@isTest
	private static void testSubmit()
	{
		Proposal_Code__c proposalCode = [SELECT Id, Name FROM Proposal_Code__c];

		Test.startTest();
		ProjectUtils.Response response = ProjectController.initData(proposalCode.Id);
		ProjectController.IntegrationContext context =  (ProjectController.IntegrationContext) response.value;
		response = ProjectController.submit(context.projectRecord, context);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testCreateProjectRecord()
	{
		Proposal_Code__c proposalCode = [SELECT Id FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PDUsername',
			Project_Manager_Email__c = 'pd@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy'
		);

		Test.startTest();
		ProjectUtils.Response response = ProjectController.upsertProjectRecord(project);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
		System.assertEquals(true, ((Atlassian_Project__c) response.value).Id <> null);
	}

	@isTest
	private static void testCreateCustomerSpace()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDName',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy'
		);

		project = (Atlassian_Project__c) ProjectController.upsertProjectRecord(project).value;

		Test.startTest();
		ProjectUtils.Response response = ProjectController.createCustomerSpace(project);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testCreateCustomerSpacePages()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name, Customer_Acronym__r.Atlassian_Key__c FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);

		ConfluenceResponse.Space space = new ConfluenceResponse.Space();
		space.id = 12345;
		space.key = 'TESTCA';
		space.name = 'Test Account';
		space.homepage = new ConfluenceResponse.Content();
		space.homepage.id = '12345';
		space.homepage.title = 'Test Account Homepage';
		space.homepage.type = 'page';

		Test.startTest();
		ProjectUtils.Response response = ProjectController.createCustomerSpacePages(project, space);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testUpdateCustomerSpacePages()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name, Customer_Acronym__r.Atlassian_Key__c FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);

		Test.startTest();
		ProjectUtils.Response response = ProjectController.updateCustomerEidPage(project);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testUpdateCustomerSpacePagesPermissions()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode,
			Published_in_Confluence__c = true,
			Published_in_Jira__c = true
		);
		insert project;

		ProjectController.IntegrationContext context = new ProjectController.IntegrationContext();

		context.initContext(proposalCode.Id);
		Atlassian_Project__c projectNew = project.clone(true, true, true, true);
		projectNew.Project_Director_Name__c = 'PDName';
		projectNew.Project_Director_Username__c = 'PDUsername';
		projectNew.Project_Director_Email__c = 'pd@mail.com';
		projectNew.Project_Manager_Name__c = 'PMName';
		projectNew.Project_Manager_Username__c = 'PMUsername';
		projectNew.Project_Manager_Email__c = 'pm@mail.com';

		context.oldProjectRecord = project;
		context.projectRecord = projectNew;

		context.setSteps(context.projectRecord);

		Test.startTest();
		ProjectUtils.Response response = ProjectController.updateCustomerSpacePagesPermissions(context);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testUpdateEidSpacePermissions()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode,
			Published_in_Confluence__c = true,
			Published_in_Jira__c = true
		);
		insert project;

		ProjectController.IntegrationContext context = new ProjectController.IntegrationContext();

		context.initContext(proposalCode.Id);
		Atlassian_Project__c projectNew = project.clone(true, true, true, true);
		projectNew.Project_Director_Name__c = 'PDName';
		projectNew.Project_Director_Username__c = 'PDUsername';
		projectNew.Project_Director_Email__c = 'pd@mail.com';
		projectNew.Project_Manager_Name__c = 'PMName';
		projectNew.Project_Manager_Username__c = 'PMUsername';
		projectNew.Project_Manager_Email__c = 'pm@mail.com';

		context.oldProjectRecord = project;
		context.projectRecord = projectNew;

		context.setSteps(context.projectRecord);

		Test.startTest();
		ProjectUtils.Response response = ProjectController.updateEidSpacePermissions(context);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testCreateCustomerEidSpacePage()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name, Customer_Acronym__r.Atlassian_Key__c FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);
		insert project;

		Test.startTest();
		ProjectUtils.Response response = ProjectController.createCustomerEidSpacePage(project);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testAddSpacePagesPermissions()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name, Customer_Acronym__r.Atlassian_Key__c FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);
		insert project;

		Test.startTest();
		ProjectUtils.Response response = ProjectController.addCustomerSpacePagesPermissions(project, true);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testCreateEidSpace()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);
		insert project;

		Test.startTest();
		ProjectUtils.Response response = ProjectController.createEidSpace(project);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testCreateEidSpacePages()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);

		ConfluenceResponse.Space space = new ConfluenceResponse.Space();
		space.id = 12345;
		space.key = '11TESTCA01001';
		space.name = '11TESTCA01001';
		space.homepage = new ConfluenceResponse.Content();
		space.homepage.id = '12345';
		space.homepage.title = '11TESTCA01001 Homepage';
		space.homepage.type = 'page';

		Test.startTest();
		ProjectUtils.Response response = ProjectController.createEidSpacePages(project, space);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testAddEidSpacePagesPermissions()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);
		insert project;

		Test.startTest();
		ProjectUtils.Response response = ProjectController.addEidSpacePagesPermissions(project);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testCreateJiraProject()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);
		insert project;

		Test.startTest();
		ProjectUtils.Response response = ProjectController.createJiraProject(project);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testUpdateJiraProject()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);
		insert project;

		JiraResponse.Project jiraProject = new JiraResponse.Project();
		jiraProject.id = '12345';
		jiraProject.key = 'project';
		JiraResponse.Project templateProject = new JiraResponse.Project();

		JiraResponse.Component cmp = new JiraResponse.Component();
		cmp.assigneeType = 'default';
		cmp.project = 'project';
		cmp.lead = null;
		cmp.projectId = 3124;

		Test.startTest();
		ProjectUtils.Response response = ProjectController.updateJiraProject(project, jiraProject, templateProject);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testUpdatePublishedJiraProject()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode,
			Published_in_Confluence__c = true,
			Published_in_Jira__c = true
		);
		insert project;

		ProjectController.IntegrationContext context = new ProjectController.IntegrationContext();

		context.initContext(proposalCode.Id);
		Atlassian_Project__c projectNew = project.clone(true, true, true, true);
		projectNew.Project_Director_Name__c = 'PDName';
		projectNew.Project_Director_Username__c = 'PDUsername';
		projectNew.Project_Director_Email__c = 'pd@mail.com';
		projectNew.Project_Manager_Name__c = 'PMName';
		projectNew.Project_Manager_Username__c = 'PMUsername';
		projectNew.Project_Manager_Email__c = 'pm@mail.com';

		context.oldProjectRecord = project;
		context.projectRecord = projectNew;

		context.setSteps(context.projectRecord);

		Test.startTest();
		ProjectUtils.Response response = ProjectController.updatePublishedJiraProject(context);
		Test.stopTest();

		System.debug(response.message);
		System.debug(response.value);
		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testUpdatePublishedJiraProjectRemovePermissions()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode,
			Published_in_Confluence__c = true,
			Published_in_Jira__c = true,
			Project_Director_Name__c = 'PDName',
			Project_Director_Username__c = 'PDUsername',
			Project_Director_Email__c = 'pd@mail.com',
			Project_Manager_Name__c = 'PMName',
			Project_Manager_Username__c = 'PMUsername',
			Project_Manager_Email__c = 'pm@mail.com'
		);
		insert project;

		ProjectController.IntegrationContext context = new ProjectController.IntegrationContext();

		context.initContext(proposalCode.Id);
		Atlassian_Project__c projectNew = project.clone(true, true, true, true);
		projectNew.Project_Director_Name__c = null;
		projectNew.Project_Director_Username__c = null;
		projectNew.Project_Director_Email__c = null;
		projectNew.Project_Manager_Name__c = null;
		projectNew.Project_Manager_Username__c = null;
		projectNew.Project_Manager_Email__c = null;

		context.oldProjectRecord = project;
		context.projectRecord = projectNew;

		context.setSteps(context.projectRecord);

		Test.startTest();
		ProjectUtils.Response response = ProjectController.updatePublishedJiraProject(context);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testAddComponents()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Test.startTest();
		AtlassianModel.Project model = new AtlassianModel.Project();
		JiraResponse.Project templateProject = new JiraResponse.Project();
		templateProject.components = new List<JiraResponse.Component>();
		JiraResponse.Component component = new JiraResponse.Component();
		component.assigneeType = 'test';
		component.lead = 'test';
		component.project = 'test';
		component.projectId = 111;
		templateProject.components.add(component);
		ProjectUtils.Response response = AtlassianServices.addTemplateComponentsToEidProject(model, templateProject);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void testNotifyUsers()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Email__c = 'test@mail.com',
			Project_Manager_Email__c = 'test@mail.com',
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode
		);
		insert project;

		ProjectController.IntegrationContext context = new ProjectController.IntegrationContext();
		context.initContext(proposalCode.Id);

		Test.startTest();
		ProjectUtils.Response response = ProjectController.notifyUsers(context, true);
		Test.stopTest();

		System.assertEquals(true, response.isSuccess);
	}

	@isTest
	private static void checkUsersChanges()
	{
		Test.setMock(HttpCalloutMock.class, new AtlassianConnectorMock());

		Proposal_Code__c proposalCode = [SELECT Id, Opportunity__r.Account.Name, Name, Customer_Acronym__r.Name FROM Proposal_Code__c];

		Atlassian_Project__c project = new Atlassian_Project__c(
			Proposal_Code__c = proposalCode.Id,
			Project_Director_Name__c = null,
			Project_Director_Username__c = null,
			Project_Director_Email__c = null,
			Project_Manager_Name__c = null,
			Project_Manager_Username__c = null,
			Project_Manager_Email__c = null,
			Project_Name__c = 'Test Project',
			Project_Status__c = 'Backlog',
			Project_Classifications__c = 'Consultancy',
			Proposal_Code__r = proposalCode,
			Published_in_Confluence__c = true,
			Published_in_Jira__c = true
		);
		insert project;

		ProjectController.IntegrationContext context = new ProjectController.IntegrationContext();

		Test.startTest();
		Atlassian_Project__c projectNew = project.clone(true, true, true, true);
		projectNew.Project_Director_Name__c = 'PDName';
		projectNew.Project_Director_Username__c = 'PDUsername';
		projectNew.Project_Director_Email__c = 'pd@test.com';
		projectNew.Project_Manager_Name__c = 'PMName';
		projectNew.Project_Manager_Username__c = 'PMUsername';
		projectNew.Project_Manager_Email__c = 'pm@test.com';
		context.projectRecord = projectNew;
		context.setSteps(projectNew);
		context.initContext(proposalCode.Id);
		context.getUsersToChange();
		Test.stopTest();

		System.assertEquals(6, context.steps.size());
	}
}