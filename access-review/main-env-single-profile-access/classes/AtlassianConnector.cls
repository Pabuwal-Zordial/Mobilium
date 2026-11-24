public with sharing class AtlassianConnector
{
	public static ProjectUtils.Response doRequest(String endpoint, String method, Object body)
	{
		try
		{
			Atlassian_Configs__c atlassianConfigs = Atlassian_Configs__c.getOrgDefaults();

			System.debug('Endpoint: ' + endpoint);
			System.debug('Method: ' + method);

			Http http = new Http();
			HttpRequest request = new HttpRequest();
			request.setEndpoint(endpoint);
			request.setMethod(method);
			request.setHeader('Content-Type', 'application/json;charset=UTF-8');
			request.setHeader('Authorization', 'Basic ' + atlassianConfigs.Token__c);
			request.setTimeout(12000);

			if (body != null)
			{
				System.debug(JSON.serializePretty(body));
				request.setBody(JSON.serialize(body, true));
			}

			HttpResponse response = http.send(request);

			if (String.valueOf(response.getStatusCode()).startsWith('20'))
			{
				System.debug(response.getBody());
				return new ProjectUtils.Response(true, String.valueOf(response.getStatusCode()),response.getBody());
			}
			return new ProjectUtils.Response(false, String.valueOf(response.getStatusCode()), response.getStatus());
		}
		catch (Exception ex)
		{
			return new ProjectUtils.Response(false, ex.getMessage(), ex.getStackTraceString());
		}
	}
}