import "commonReactions/all.dsl";

context
{
  input phone: string;
  
  first_name: string = "";
  last_name: string = "";
  
  user_address: Address =
  {
    street_num: "",
    street: "",
    city: "",
    state: "",
    zip_code: ""
  }
  ;
  
  branch: Branch?;
  
  follow_up_question: string?;
  follow_up_data: string?;
}

type SpeechFaq =
{
  verbal_response: string?;
  follow_up_question: string?;
  follow_up_data: string?;
}
;

type Branch =
{
  address: string;
  open_time: string;
  close_time: string;
  is_closed: boolean;
  next_open_day: string;
}
;

type Address =
{
  street_num: string;
  street: string;
  city: string;
  state: string;
  zip_code: string;
}
;

external function lookForBranch(street_num: string, street: string, city: string, state: string, zip_code: string): Branch;
external function searchSpeechFaq(query: string): SpeechFaq;
external function bookAppointment(): empty;

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

digression greeting
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
    var speechFaq: SpeechFaq = external searchSpeechFaq(sentence);
    var response = speechFaq.verbal_response;
    set $follow_up_question = speechFaq.follow_up_question;
    set $follow_up_data = speechFaq.follow_up_data;
    
    #log($follow_up_question);
    
    if(response is not null)
    {
      #sayText(response);
      
      if($follow_up_question is not null)
      {
        wait
        {
          follow_up
        }
        ;
      }
      else
      {
        goto can_help_else;
      }
    }
    else
    {
      #say("dont_understand_request");
      wait *;
    }
  }
  transitions
  {
    can_help_else: goto can_help_else;
    follow_up: goto follow_up on #messageHasIntent("yes");
    // handle_question: goto handle_question on #getSentenceType() == "question";
  }
}

node follow_up
{
  do
  {
    if($follow_up_question is not null)
    {
      if($follow_up_data is null)
      {
        #sayText($follow_up_question);
      }
      else if($follow_up_data == "address")
      {
        var user_address: Address = blockcall gather_address($follow_up_question);
        // TODO: account for address already being stored
        #sayText("New address was saved.");
      }
    }
    
    goto can_help_else;
  }
  transitions
  {
    can_help_else: goto can_help_else;
  }
  onexit
  {
    can_help_else: do
    {
      set $follow_up_question = null;
      set $follow_up_data = null;
    }
  }
}

node can_help_else
{
  do
  {
    #sayText("Is there anything else I can help you with today?");
    wait*;
  }
  transitions
  {
    handle_question: goto handle_question on #getSentenceType() == "question";
    thats_it_bye: goto no_more_questions on #messageHasIntent("no");
  }
}

digression branch_search
{
  conditions
  {
    on #messageHasIntent("locate_branch");
  }
  do
  {
    // TODO: persist user address if user_street exists
    var user_address: Address = blockcall gather_address("I can certainly help with that. Could you provide me with your address or zip code?");
    // TODO: modify lookForBranch to return hours
    set $branch = external lookForBranch(user_address.street_num, user_address.street, user_address.city, user_address.state, user_address.zip_code);
    
    if($branch is not null)
    {
      #sayText("So it looks like we have a branch at " + $branch.address + ". Would you like me to make an appoinment for you?");
    }
    else
    {
      #sayText("Sorry. It looks like we don't have a branch in your area.");
      goto can_help_else_direct;
    }
    wait *;
  }
  transitions
  {
    schedule_appointment: goto schedule_appointment on #messageHasIntent("yes");
    can_help_else: goto can_help_else on #messageHasIntent("no");
    can_help_else_direct: goto can_help_else;
  }
}

digression check_branch_hours
{
  conditions
  {
    on #messageHasIntent("branch_hours");
  }
  do
  {
    if($branch is not null)
    {
      if($branch.is_closed)
      {
        #sayText("The branch at " + $branch.address + " is closed today. It will reopen on " + $branch.next_open_day);
      }
      else
      {
        #sayText("The branch at " + $branch.address + " is open from " + $branch.open_time + " to " + $branch.close_time + " today.");
      }
    }
    else
    {
      // TODO: persist user address if user_street exists
      var user_address: Address = blockcall gather_address("Can you provide me an address or zip code so that I can check the hours of the branch closest to you?");
      set $branch = external lookForBranch(user_address.street_num, user_address.street, user_address.city, user_address.state, user_address.zip_code);
      
      if($branch is not null)
      {
        if($branch.is_closed)
        {
          #sayText("The branch at " + $branch.address + " is closed today. It will reopen on " + $branch.next_open_day + " at " + $branch.open_time);
        }
        else
        {
          #sayText("The branch at " + $branch.address + " is open from " + $branch.open_time + " to " + $branch.close_time + " today.");
        }
      }
      else
      {
        #sayText("Sorry. It looks like we don't have a branch in your area.");
      }
    }
    goto can_help_else;
  }
  transitions
  {
    can_help_else: goto can_help_else;
  }
}

// TODO: handle when user doesnt say address
block gather_address(capture_address_message: string): Address
{
  start node request_address
  {
    do
    {
      #sayText($capture_address_message);
      wait *;
    }
  }
  
  digression capture_address
  {
    conditions
    {
      on #messageHasData("street") or #messageHasData("zip_code");
    }
    do
    {
      var user_street_num = #messageGetData("street_num")[0]?.value ?? "";
      var user_street = #messageGetData("street")[0]?.value ?? "";
      var user_city = #messageGetData("city")[0]?.value ?? "";
      var user_state = #messageGetData("state")[0]?.value ?? "";
      var user_zip_code = #messageGetData("zip_code")[0]?.value ?? "";
      
      return
      {
        street_num: user_street_num,
        street: user_street,
        city: user_city,
        state: user_state,
        zip_code: user_zip_code
      }
      ;
    }
  }
}

node schedule_appointment
{
  do
  {
    #sayText("Ok. What day and time were you thinking");
    wait *;
  }
}

digression book_appointment
{
  conditions
  {
    on #messageHasData("time") and #messageHasData("day_of_week");
  }
  do
  {
    var time =  #messageGetData("time")[0]?.value??"";
    var day_of_week =  #messageGetData("day_of_week")[0]?.value??"";
    #sayText("Just give me one moment and I'll get that booked for you.");
    external bookAppointment();
    #sayText("Ok. You're all set for " + day_of_week + " at " + time);
    goto can_help_else;
  }
  transitions
  {
    can_help_else: goto can_help_else;
  }
}

node no_more_questions
{
  do
  {
    #sayText("No problem, happy to help. I hope you have a great rest of your day. Bye!");
    #disconnect();
    exit;
  }
}

digression thats_it_bye
{
  conditions
  {
    on #messageHasIntent("that_would_be_it");
  }
  
  do
  {
    #sayText("No problem, happy to help. I hope you have a great rest of your day. Bye!");
    #disconnect();
    exit;
  }
}
