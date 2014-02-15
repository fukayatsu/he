(function(){
  var alertMessage = function(text, type) {
    if (!type) { type = 'success' }
    $("#alert_message").text(text);
    $("#alert").attr('class', 'alert fade in alert-' + type);
    setTimeout(function() {
      $("#alert").removeClass('in');
      $("#alert_message").text("");
    }, 3000);
  }

  function valueChanged(settings){
    $('#api_endpoint').val(settings.api_endpoint);
    $('#username').val(settings.username);
    $('#password').val(settings.password);
    console.log('value changed.');
  }

  $(document).on('click', '#save_settings', function(event) {
    var settings = {
      "api_endpoint": $('#api_endpoint').val(),
      "username": $('#username').val(),
      "password":   $('#password').val()
    }
    chrome.storage.sync.set({settings: JSON.stringify(settings)}, function() {
      console.log('setting saved.');
    });
    event.preventDefault();
  });

  $(document).on('click', '[data-remote]', function(event) {
    var command = $(this).data('remote')

    $.ajax({
      type: "POST",
      url: $('#api_endpoint').val() + '/remote',
      username: $('#username').val(),
      password: $('#password').val(),
      data: { command: command },
      success: function(res) {
        alertMessage('[sent] ' + command);
      },
      error: function (res) {
        alertMessage('[failure] ' + command, 'danger');
      }
    });

  });

  chrome.storage.onChanged.addListener(function(changes, namespace) {
    if (changes["settings"]) {
      valueChanged(JSON.parse(changes["settings"].newValue));
      console.log('chrome.storage.onChanged');
    }
  });
  chrome.storage.sync.get("settings", function(data) {
    valueChanged(JSON.parse(data.settings));
    console.log('chrome.storage.sync.get')
  });
  console.log('start')

})();