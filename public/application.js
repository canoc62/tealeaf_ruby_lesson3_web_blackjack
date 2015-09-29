$(document).ready(function(){

  $(document).on('click', '#hit', function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/hit'
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });

  $(document).on('click', '#stay', function() {
    $.ajax({
      type: 'POST',
      url: '/game/player/stay'
    }).done(function(msg){
      $('#game').replaceWith(msg);
    });
    return false;
  });
});