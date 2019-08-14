<?php
    $metadata = fopen($_POST['submit'], "r") or die("Unable to open file!");
    echo $metadata;
?>