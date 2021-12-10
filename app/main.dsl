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
}

digression start_session
{
  conditions
  {
    on #getSentenceType() == "question" or #getSentenceType() == "statement" or #getSentenceType() == "request";
  }
  do
  {
    var sentence = #getMessageText();
    var speechFaq: string[] = external searchSpeechFaq(sentence);
    var response = speechFaq[0];
    var followUpQuestion = speechFaq[1];
    
    if(response is not null)
    {
      #sayText(response);
      if(followUpQuestion is not null)
      {
        #log(followUpQuestion);
        // TODO: apply logic here to wait for a yes or no response and act accordingly
      }
    }
    else
    {
      #sayText("Sorry I'm not sure I understood. Could you ask that again?");
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
