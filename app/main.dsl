import "commonReactions/all.dsl";

context
{
  input phone: string;
  
  first_name: string = "";
  last_name: string = "";
  street_num: string="";
  street: string="";
  city: string="";
  state: string="";
  zip_code: string="";
  
  follow_up_question: string?;
}

// type SpeechFaq =
// {
//   response?: string;
//   followUpQuestion?: string;
// };

external function lookForBranch(street_num: string, street: string, city: string, state: string, zip_code: string): string;
external function searchSpeechFaq(query: string): string[];

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
  transitions
  {
    handle_question: goto handle_question on (#getSentenceType() == "question" or #getSentenceType() == "statement" or #getSentenceType() == "request");
  }
}

node handle_question
{
  do
  {
    var sentence = #getMessageText();
    var speechFaq: string[] = external searchSpeechFaq(sentence);
    var response = speechFaq[0];
    set $follow_up_question = speechFaq[1];
    
    #log($follow_up_question);
    
    if(response is not null)
    {
      #sayText(response);
    }
    else
    {
      #say("dont_understand_request");
    }
    wait *;
  }
  transitions
  {
    follow_up: goto follow_up on #messageHasIntent("yes");
  }
}

node follow_up
{
  do
  {
    if($follow_up_question is not null)
    {
      #sayText($follow_up_question);
    }
    
    wait *;
  }
}

// digression branch_search
// {
//   conditions
//   {
//     on #messageHasIntent("locate_branch");
//   }
//   do
//   {
//     #sayText("I can certainly help with that. Could you provide me with your address or zip code?");
//     wait *;
//   }
// }

// digression set_zip_code
// {
//   conditions
//   {
//     on #messageHasData("zip_code") and !#messageHasData("street_num") and !#messageHasData("street_name") and !#messageHasData("city") and !#messageHasData("state");
//   }
//   do
//   {
//     set $zip_code = #messageGetData("zip_code")[0]?.value ?? "";
//     #sayText("Ok let me see if I can find a branch close by, just give me one second.");
//     var branch_response = external lookForBranch($street_num, $street, $city, $state, $zip_code);
//     #sayText("The closest branch I can find to you is located at " + branch_response);
//   }
// }

// digression set_address
// {
//   conditions
//   {
//     on #messageHasData("street_name") or #messageHasData("city") or !#messageHasData("state");
//   }
//   do
//   {
//     set $street_num = #messageGetData("street_num")[0]?.value ?? "";
//     set $street = #messageGetData("street")[0]?.value ?? "";
//     set $city = #messageGetData("city")[0]?.value ?? "";
//     set $state = #messageGetData("state")[0]?.value ?? "";
//     #sayText("Ok let me see if I can find a branch close by, just give me one second.");
//     var branch_response = external lookForBranch($street_num, $street, $city, $state, $zip_code);
//   }
// }
