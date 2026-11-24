import { LightningElement } from 'lwc';
export default class BasicCalculation extends LightningElement {

    firstInput;
    secondInput;
    totalValue;
    showResult;

    additionOfTwoNumbers(num){
        console.log('This is called',num)
            return num+1;

    }

    FirstInputChange(event)
    {
        this.firstInput = event.target.value;
    }
    SecondInputChange(event) 
    {
        this.secondInput = event.target.value;
        this.showResult = false;
    }
    add(event)
    {
        this.totalValue = Number(this.firstInput) + Number(this.secondInput);
        this.showResult = true;
    }
    sub(event){
        this.totalValue = this.firstInput - this.secondInput;
        this.showResult = true;
    }
    mul(event){
        this.totalValue = this.firstInput * this.secondInput;
        this.showResult = true;
    }
    div(event){
        this.totalValue = this.firstInput / this.secondInput;
        this.showResult = true;
    }


}