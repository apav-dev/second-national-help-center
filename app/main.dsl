// import "commonReactions/all.dsl";

context
{
  // declare input variables phone and name  - these variables are passed at the outset of the conversation. In this case, the phone number and customer’s name
  input phone: string;
  
  // declare storage variables
  output first_name: string = "";
  output last_name: string = "";
}

start node root //start node
{
  do
  {
    #connectSafe($phone); //connect via phone
    #waitForSpeech(1000);
    #say("welcome");
    wait *; //wait for user speech
  }
  transitions
  {
  }
}

digression how_may_i_help
{
  conditions
  {
    on #messageHasData("first_name");
  }
  
  do
  {
    set $first_name =  #messageGetData("first_name")[0]?.value??"";
    set $last_name =  #messageGetData("last_name")[0]?.value??"";
    #sayText("Awesome, nice to meet you " + $first_name + ", how may I assist you today?");
    wait *;
  }
}
