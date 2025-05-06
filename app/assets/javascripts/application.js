// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery3
//= require popper
//= require bootstrap
//= require rails-ujs
//= require turbolinks
//= require_tree .

document.addEventListener('turbolinks:load', function() {
  // Initialize tooltips
  $('[data-toggle="tooltip"]').tooltip();
  
  // Initialize popovers
  $('[data-toggle="popover"]').popover();
  
  // Image upload preview
  $('.custom-file-input').on('change', function() {
    var fileName = $(this).val().split('\\').pop();
    $(this).siblings('.custom-file-label').addClass('selected').html(fileName);
    
    // Preview image
    if (this.files && this.files[0]) {
      var reader = new FileReader();
      reader.onload = function(e) {
        $('#imagePreview').attr('src', e.target.result).show();
      }
      reader.readAsDataURL(this.files[0]);
    }
  });
});