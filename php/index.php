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

// Sender of the crash report
define('SENDER_EMAIL', 'crashreport@example.com');
define('SENDER_NAME', 'Crash Report Mailer');

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
    $mail->SMTPSecure = 'tls';
    $mail->Port       = SMTP_PORT;

    //Recipients
    $mail->setFrom(SENDER_EMAIL, SENDER_NAME);
    $mail->addAddress(SUPPORT_EMAIL, SUPPORT_NAME);
    if (isset($userEmail) && $userEmail !== '') {
        $mail->addCC($userEmail);
    }

    // Attachments
    $mail->addAttachment($path, $filename);

    // Content
    $mail->Subject = 'Crash log ' . $filename;
    $message = 'Crash log processed on ' . date("Y-m-d H:i:s") . "\n\n";
    $mail->Body    = $message;
    $mail->AltBody = $message;

    $mail->send();
}

// Collect request data
$crashlog = $_POST['crashlog'];
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

$filename = date("YmdHis") . ' ' . $app . '.crash';
$userEmail = ''; // TODO: collect sender email to get back in touch

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

