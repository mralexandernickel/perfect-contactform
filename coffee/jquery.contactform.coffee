#
# requires jquery, bootstrap, mandrill-api, recaptcha-api and a server-side recaptcha verification script
#
$ = jQuery

config =
  mandrill_key: null
  recaptcha_pubkey: null
  from_email: null
  recaptcha_verification_url: "/recaptcha_verification.php"
  recipients: []
  recaptcha_placeholder_text: "Bitte gib die 2 Worte ein..."
  button_text: "Absenden"
  button_sending_text: "Wird Gesendet..."
  button_sent_text: "Gesendet!"
  form_el: null
  btn_submit: null
  mandrill: null

methods =
  #
  # init
  #
  init: (options) ->
    # set options
    $.extend config, options
    
    # set the form element if form exists in DOM
    if $(this).parent().length > 0
      config.form_el = $(this)
      
      try
        methods.init_mandrill()
        methods.init_recaptcha()
        methods.bind_submit_handler()
      catch error
        console.log error if console?
    else
      console.log "you need to define a form element!" if console?
  
  #  
  # init mandrill
  #
  init_mandrill: ->
    if mandrill?
      config.mandrill = new mandrill.Mandrill config.mandrill_key
    else
      $.error "the perfect contactform needs the Mandrill API"
  
  #
  # init recaptcha
  #
  init_recaptcha: ->
    if Recaptcha?
      # define the markup
      recaptcha_modal = """<div class="modal" id="modal_recaptcha" tabindex="-1" role="dialog" aria-labelledby="modal_recaptcha" aria-hidden="true">
          <div class="modal-dialog">
            <div class="modal-content">
              <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
                <h4 class="modal-title">Modal title</h4>
              </div>
              <div class="modal-body">
                <div id="recaptcha_wrap">
                  <div id="recaptcha_widget">
                    <div class="clearfix">
                      <div id="recaptcha_image" class="pull-left"></div>
                      <div class="pull-right">
                        <button id="recaptcha_reload" class="btn btn-default"><i class="icon-repeat"></i> </button>
                      </div>
                    </div>
                    <input type="text" id="recaptcha_response_field" class="form-control" placeholder="#{config.recaptcha_placeholder_text}" name="recaptcha_response_field" />
                  </div>
                </div>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-primary" id="btn_send_contactform">#{config.button_text}</button>
              </div>
            </div>
          </div>
        </div>"""

      config.form_el.after recaptcha_modal
      
      # set the button states
      methods.set_button_states()
      
      # bind click-event to button
      config.btn_submit = $("#btn_send_contactform")
      config.btn_submit.click (e) ->
        e.preventDefault()
        methods.send_contactform()
      
      # load recaptcha
      Recaptcha.create recaptcha_pubkey,
        "recaptcha_wrap",
          theme: "custom"
          custom_theme_widget: "recaptcha_widget"
      
      # add event to reload button
      $("#recaptcha_reload").click (e) ->
        Recaptcha.reload()
    else
      $.error "the perfect contactform needs the ReCaptcha API"
  
  #
  # set the submit button states
  #
  set_button_states: ->
    config.btn_submit.attr
      "data-sending-text": config.button_sending_text
      "data-sent-text": config.button_sent_text
  
  #
  # open the modal
  #
  open_modal: ->
    $("#modal_recaptcha").modal "show"
  
  
  #
  # close the modal
  #
  close_modal: ->
    $("#modal_recaptcha").modal "hide"
  
  #
  # verify recaptcha and send form
  #
  send_contactform: ->
    # bring submit button into sending state
    config.btn_submit.button "sending"
    
    # define params for recaptcha verification
    recaptcha_params =
      recaptcha_response_field: Recaptcha.get_response()
      recaptcha_challenge_field: Recaptcha.get_challenge()
    
    # verify recaptcha
    $.post config.recaptcha_verification_url, recaptcha_params, (response) ->
      # recaptcha is correct...
      if response is 1
        # close the modal
        methods.close_modal()
        # set mandrill params
        mandrill_params =
          message:
            from_email: $("#input_email").val()
            from_name: $("#input_name").val()
            to: config.recipients
            subject: $("#input_subject").val()
            text: $("#input_message").val()
        
        # send the message
        m.messages.send mandrill_params, (res) ->
          console.log res if console?
          # output message
          
          # set button into sent state
          config.btn_submit.button "sent"
          
          # reload recaptcha
          Recaptcha.reload()
          
          # reset the form
          config.form_el[0].reset()
        , (err) ->
          console.log err if console?
      # recaptcha is wrong...
      else
        console.log "the recaptcha solution is wrong" if console?
  
  #
  # bind the forms submit event
  #
  bind_submit_handler: ->
    config.form_el.submit (e) ->
      # prevent form from sending
      e.preventDefault()
      # open the modal
      methods.open_modal()
      

$.fn.contactform = (method,options...) ->
  if methods[method]
    methods[method].apply this, options
  else if typeof method is "object" or not method
    methods.init.apply this, arguments
  else
    $.error "Method #{method} does not exist in Perfect Contactform"