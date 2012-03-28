$(document).ready(function(){
  $('#micropost_content').keyup(function(event) {
    var remaining = 140 - $('#micropost_content').val().length;
    if(remaining < 0){ remaining = 0 }

    $("#character_counter").html(remaining + " characters remaining"); 
  });
});
