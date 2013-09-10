<?php

require_once("recaptchalib.php");

if ($_POST["recaptcha_response_field"]) {
  $privatekey = "ENTER_YOUR_PRIVATE_KEY";
  
  $resp = recaptcha_check_answer($privatekey, $_SERVER["REMOTE_ADDR"], $_POST["recaptcha_challenge_field"], $_POST["recaptcha_response_field"]);
  
  if ($resp->is_valid) {
    $status = true;
  } else {
    # set the error code so that we can display it
    $error = $resp->error;
    $status = false;
  }
}

header('Content-type: application/json');
echo $status;

?>