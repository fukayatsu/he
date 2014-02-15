var alertMessage = function(text, type) {
  if (!type) { type = 'success' }
  $("#alert_message").text(text);
  $("#alert").attr('class', 'alert fade in alert-' + type);
  setTimeout(function() {
    $("#alert").removeClass('in')}
  , 3000
  );
}

$(document).on('click', '[data-remote]', function(event) {
  var command = $(this).data('remote')

  $.ajax({
    type: "POST",
    url: '/remote',
    data: { command: command },
    success: function(res) {
      alertMessage('[sent] ' + command);
    },
    error: function (res) {
      alertMessage('[failure] ' + command, 'danger');
    }
  });

});
