({
	/*************************************************************************************
      Method Name             doInit
      Developed By            West Monroe Partners
      Purpose                 * To populate the following
						* pushing the default values into other placeholders

      Created date            2/3/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/3/2017		Refer method header
      *************************************************************************************/
  	doInit : function(component, event, helper) {
            //Now we will set a var called rowTotal and calculate..
            //If blank it will be zero
            var rowTotal = Number(isNaN(component.get("v.milestone.PO__c"))?0:component.get("v.milestone.PO__c")) +
                           Number(isNaN(component.get("v.milestone.Contract__c"))?0:component.get("v.milestone.Contract__c")) +
                           Number(isNaN(component.get("v.milestone.HW_delivery__c"))?0:component.get("v.milestone.HW_delivery__c")) +
                           Number(isNaN(component.get("v.milestone.HW_Install__c"))?0:component.get("v.milestone.HW_Install__c")) +
                           Number(isNaN(component.get("v.milestone.SW_delivery__c"))?0:component.get("v.milestone.SW_delivery__c")) +
                           Number(isNaN(component.get("v.milestone.RFA__c"))?0:component.get("v.milestone.RFA__c")) +
                           Number(isNaN(component.get("v.milestone.UAT__c"))?0:component.get("v.milestone.UAT__c")) +
                           Number(isNaN(component.get("v.milestone.Stability__c"))?0:component.get("v.milestone.Stability__c")) +
                           Number(isNaN(component.get("v.milestone.FA__c"))?0:component.get("v.milestone.FA__c")) +
                           Number(isNaN(component.get("v.milestone.KPI__c"))?0:component.get("v.milestone.KPI__c")) +
                           Number(isNaN(component.get("v.milestone.Retention__c"))?0:component.get("v.milestone.Retention__c"));

            if(isNaN(rowTotal))
                  rowTotal = 0;

            //getting the column ID
            var cmpTarget = component.find('totalRowId');

            //Changing the background color from red/green and vice versa
            if(rowTotal != 100){
                  $A.util.addClass(cmpTarget, 'not100');
                  $A.util.removeClass(cmpTarget, 'equalTo100');
            }
            else{
                  $A.util.addClass(cmpTarget, 'equalTo100');
                  $A.util.removeClass(cmpTarget, 'not100');
            }
            //Ensuring that the milestone is carried
            var runningMilestone = component.get("v.milestone");
            runningMilestone.Total_Percentage__c = rowTotal;
            component.set("v.milestone", runningMilestone);
            
            component.set("v.totalRowPercentage", rowTotal);

  	},
      /*************************************************************************************
      Method Name             updateTotalAndValidate
      Developed By            West Monroe Partners
      Purpose                 * To populate the total percentage for the row
					* validate if 100 is the list
      Created date            2/3/2017
      History
      ------------------------------------------------------------------------------------
      VERSION  	AUTHOR 	DATE      		DETAIL
      1.0		SS		2/3/2017		Refer method header
      *************************************************************************************/
  	updateTotalAndValidate : function(component, event, helper) {
            //Ensuring that the milestone is carried
            var runningMilestone = component.get("v.milestone");

            //runningMilestone.Contract__c = Number(isNaN(runningMilestone.Contract__c)?0:runningMilestone.Contract__c);
            //console.log(runningMilestone.Contract__c + ' -- ' + Number(component.get("v.milestone").Contract__c));
            var rowTotal = Number(isNaN(runningMilestone.PO__c)?0:runningMilestone.PO__c) +
                           Number(isNaN(runningMilestone.Contract__c)?0:runningMilestone.Contract__c) +
                           Number(isNaN(runningMilestone.HW_delivery__c)?0:runningMilestone.HW_delivery__c) +
                           Number(isNaN(runningMilestone.HW_Install__c)?0:runningMilestone.HW_Install__c) +
                           Number(isNaN(runningMilestone.SW_delivery__c)?0:runningMilestone.SW_delivery__c) +
                           Number(isNaN(runningMilestone.RFA__c)?0:runningMilestone.RFA__c) +
                           Number(isNaN(runningMilestone.UAT__c)?0:runningMilestone.UAT__c) +
                           Number(isNaN(runningMilestone.Stability__c)?0:runningMilestone.Stability__c) +
                           Number(isNaN(runningMilestone.FA__c)?0:runningMilestone.FA__c) +
                           Number(isNaN(runningMilestone.KPI__c)?0:runningMilestone.KPI__c) +
                           Number(isNaN(runningMilestone.Retention__c)?0:runningMilestone.Retention__c);

            if(isNaN(rowTotal))
                  rowTotal = 0;
            //getting the column ID
            var cmpTarget = component.find('totalRowId');

            //Changing the background color from red/green and vice versa
            if(rowTotal != 100){
                  $A.util.addClass(cmpTarget, 'not100');
                  $A.util.removeClass(cmpTarget, 'equalTo100');
            }
            else{
                  $A.util.addClass(cmpTarget, 'equalTo100');
                  $A.util.removeClass(cmpTarget, 'not100');
            
            }
            runningMilestone.Total_Percentage__c = rowTotal;
            component.set("v.milestone", runningMilestone);
            component.set("v.totalRowPercentage", rowTotal);
      }
})