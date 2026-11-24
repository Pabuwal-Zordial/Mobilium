/*************************************************************************************
Class Name             clsUtility
Developed By            West Monroe Partners
Purpose                 Refer class headers
Created date            6/8/2017
*************************************************************************************/
public class clsUtility {

	/*************************************************************************************
      Method Name             queryRecordWithFilter
      Developed By            West Monroe Partners
      Purpose                 To construct a default query for a specific obeject. 
	 					No Object or field dependency
	 Input				* String objectName
	 					* String relationshipFields
						* String filterCriteria

      Created date            6/8/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0			SS		6/8/2017		Refer method header
      *************************************************************************************/

	public static list<sObject> queryRecordWithFilter(String str_objectName, String str_relationshipFields, String str_filterCriteria) {
		//Variables
		list<sObject> list_sObjects = new list<sObject>();
		String str_query = 'SELECT';

		//Getting all field from describe
		Map<String, Schema.SObjectField> map_objectFields = Schema.getGlobalDescribe().get(str_objectName).getDescribe().fields.getMap();
		
		// Grab the fields from the describe method and append them to the queryString one by one.
		for(String iterating_field : map_objectFields.keySet()) {
			str_query += ' ' + iterating_field + ',';
		}

		if(str_relationshipFields != '')
			str_query += str_query + str_relationshipFields;
		
		// Strip off the last comma if it exists.
		if (str_query.subString(str_query.Length()-1,str_query.Length()) == ','){
			str_query = str_query.subString(0,str_query.Length()-1);
		}

		
		// Add FROM statement
		str_query += ' FROM ' + str_objectName;

		//Adding filter criteria
		if(str_filterCriteria != '')
			str_query +=  ' WHERE ' + str_filterCriteria;
		
		System.debug('Query string is >> ' +  str_query);
		//querying
		try {
        		list_sObjects = database.query(str_query);
		} catch (Exception e){
			//perform exception handling
			System.debug(e.getMessage());
		}

		return list_sObjects;

	}
}