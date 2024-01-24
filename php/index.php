<?php

/*******************************************************************************
 *
 * Put your settings here
 *
 */

// Toggle verbose debug output to STDOUT
define('DEBUG', 0);

// SMTP Settings
define('SMTP_HOST', 'smtp.example.com');
define('SMTP_USER', 'your-user-name');
define('SMTP_PASS', 'your-smtp-password');
define('SMTP_PORT', 587);
define('SMTP_SECURE', 'tls'); // 'ssl' or 'tls'

// Sender of the crash report
define('SENDER_EMAIL', 'crashreport@example.com');
define('SENDER_NAME', 'Crash Report Mailer');
define('SEND_CC_TO_USER', true);

// Recipient of the crash report (you)
define('SUPPORT_EMAIL', 'support@example.com');
define('SUPPORT_NAME', 'Amazing App Inc. Support');

// You can provide test data to see if your email settings work at the bottom
// of this file.

/*
 * </End of Settings>
 *
 *****************************************************************************/


use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'vendor/PHPMailer/src/Exception.php';
require 'vendor/PHPMailer/src/PHPMailer.php';
require 'vendor/PHPMailer/src/SMTP.php';

function postString($key) {
    return array_key_exists($key, $_POST) ? $_POST[$key] : '';
}

function clean($userData) {
    $userData = htmlspecialchars($userData, ENT_IGNORE, 'utf-8');
    $userData = strip_tags($userData);
    $userData = trim($userData);
    return $userData;
}

function isEmpty($var) {
    return !isset($var) || strlen(trim($var)) == 0;
}

function sendEmailForReportAsFilenameForSender($path, $filename, $userEmail = '') {
    $mail = new PHPMailer(true);

    //Server settings
    if (DEBUG) {
        $mail->Debugoutput = 'echo';
        $mail->SMTPDebug = 4;
    }
    $mail->isSMTP();
    $mail->Host       = SMTP_HOST;
    $mail->SMTPAuth   = True;
    $mail->Username   = SMTP_USER;
    $mail->Password   = SMTP_PASS;
    $mail->SMTPSecure = SMTP_SECURE;
    $mail->Port       = SMTP_PORT;

    //Recipients
    $mail->setFrom(SENDER_EMAIL, SENDER_NAME);
    $mail->addAddress(SUPPORT_EMAIL, SUPPORT_NAME);
    if (!isEmpty($userEmail) && SEND_CC_TO_USER) {
        $mail->addCC($userEmail);
    }

    // Attachments
    $mail->addAttachment($path, $filename);

    // Content
    $mail->Subject = 'Crash log ' . $filename;
    $message = 'Crash log processed on ' . date("Y-m-d H:i:s") . "<br>\r\n"
      . 'Sender: ' . (!isEmpty($userEmail) ? $userEmail : '(unknown)') . "<br>\r\n<br>\r\n";
    $mail->Body    = $message;
    $mail->AltBody = $message;

    $mail->send();
}

// Collect request data
$crashlog = postString('crashlog');
$app = clean($_SERVER['HTTP_USER_AGENT']);

/*
// To test sending email from this script via `php index.php`, provide replacement data
$crashlog = "test crash  log content";
$app = "test app 2000";
 */

if (isEmpty($crashlog) || isEmpty($app)) {
    header('X-PHP-Response-Code: 401', true, 401);
    die();
}

$logIsJSON = $crashlog[0] == '{';
$filename = date("YmdHis") . ' ' . $app . ($logIsJSON ? '.ips' : '.crash');
$userEmail = postString('userEmail');

$tmpfile = tmpfile();
try {
    // Write report to file
    fwrite($tmpfile, $crashlog);
    fseek($tmpfile, 0);
    $path = stream_get_meta_data($tmpfile)['uri'];

    sendEmailForReportAsFilenameForSender($path, $filename, $userEmail);
} catch (Exception $e) { // PHPMailer exception
    header('X-PHP-Response-Code: 400', true, 400);
    echo($e->getMessage());
} catch (\Exception $e) { // Global PHP exception
    header('X-PHP-Response-Code: 400', true, 400);
    echo $e->getMessage();
} finally {
    fclose($tmpfile);
}

