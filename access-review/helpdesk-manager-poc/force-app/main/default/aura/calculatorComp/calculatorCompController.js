({
	add : function(component, event, helper) {
      var no1 =  component.get("v.Number1");
        console.log("First Number is "+no1);
      var no2 =  component.get("v.Number2");
         console.log("Second Number is " + no2);
        var noResult = Number(no1) + Number(no2);
         console.log("Result Number is "+ noResult);
        
        component.set("v.Result", noResult ); 
      
		
	},
    sub : function(component, event, helper) {
        var no1 =  component.get("v.Number1");
        console.log("First Number is "+no1);
      var no2 =  component.get("v.Number2");
         console.log("Second Number is " + no2);
        var noResult = Number(no1) - Number(no2);
         console.log("Result Number is "+ noResult);
        
        component.set("v.Result", noResult ); 
      
		
	},
    mul : function(component, event, helper) {
        var no1 =  component.get("v.Number1");
        console.log("First Number is "+no1);
      var no2 =  component.get("v.Number2");
         console.log("Second Number is " + no2);
        var noResult = Number(no1) * Number(no2);
         console.log("Result Number is "+ noResult);
        
        component.set("v.Result", noResult ); 
      
		
	},
    div : function(component, event, helper) {
       var no1 =  component.get("v.Number1");
        console.log("First Number is "+no1);
      var no2 =  component.get("v.Number2");
         console.log("Second Number is " + no2);
        var noResult = Number(no1) / Number(no2);
         console.log("Result Number is "+ noResult);
        
        component.set("v.Result", noResult ); 
      
		
		
	}
})