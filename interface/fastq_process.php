<?php
/*$ftp_server = "myftp.co.uk";
$ftp_user_name = "myusername";
$ftp_user_pass = "mypass";
$source_file = $_POST['file']['tmp_name'];
$target_dir = "uploads/";
$target_file = $target_dir . basename($_FILES["fileToUpload"]["name"]);
$uploadOk = 1;
$genomeFileType = strtolower(pathinfo($target_file,PATHINFO_EXTENSION));

// Checking file integrity
if(isset($_POST["submit"])) {
    $check = getimagesize($_FILES["fileToUpload"]["tmp_name"]);

    if($check !== false) {
        echo "File is an image - " . $check["mime"] . ".";
        $uploadOk = 1;
    }

    else {
        echo "File is not an image.";
        $uploadOk = 0;
    }
}

// Check if file already exists
if (file_exists($target_file)) {
    echo "Sorry, file already exists.";
    $uploadOk = 0;
}

// Check file size
if ($_FILES["fileToUpload"]["size"] > 50000000000) {
    echo "Sorry, your file is too large.";
    $uploadOk = 0;
}

// Allow certain file formats
if($genomeFileType != "fasta" && $genomeFileType != "fastq.gz" ) {
    echo "Sorry, only fastq and fasta files are allowed.";
    $uploadOk = 0;
}

// Check if $uploadOk is set to 0 by an error
if ($uploadOk == 0) {
    echo "Sorry, your file was not uploaded.";
// if everything is ok, try to upload file
}

else {
    if (move_uploaded_file($_FILES["fileToUpload"]["tmp_name"], $target_file)) {
        echo "The file ". basename( $_FILES["fileToUpload"]["name"]). " has been uploaded.";
    } else {
        echo "Sorry, there was an error uploading your file.";
    } "sampling" : { "quantity" : "50µg", "biopsy_source" : "Peripheral vein", "remark" : { "0" : "Species of Origin Confirmed by LINE assay" }, "transformant" : "Epstein-Barr Virus", "tissue_type" : "Blood", "cell_type" : "B-Lymphocyte" }, 
} "sampling" : { "quantity" : "50µg", "biopsy_source" : "Peripheral vein", "remark" : { "0" : "Species of Origin Confirmed by LINE assay" }, "transformant" : "Epstein-Barr Virus", "tissue_type" : "Blood", "cell_type" : "B-Lymphocyte" }, 
 "sampling" : { "quantity" : "50µg", "biopsy_source" : "Peripheral vein", "remark" : { "0" : "Species of Origin Confirmed by LINE assay" }, "transformant" : "Epstein-Barr Virus", "tissue_type" : "Blood", "cell_type" : "B-Lymphocyte" }, 
// Set u "sampling" : { "quantity" : "50µg", "biopsy_source" : "Peripheral vein", "remark" : { "0" : "Species of Origin Confirmed by LINE assay" }, "transformant" : "Epstein-Barr Virus", "tissue_type" : "Blood", "cell_type" : "B-Lymphocyte" }, p basic connection
$conn_id = ftp_connect($ftp_server);
ftp_pasv($conn_id, true);

// Login with username and password
$login_result = ftp_login($conn_id, $ftp_user_name, $ftp_user_pass); 

// Check connection
if ((!$conn_id) || (!$login_result)) { 
    echo "FTP connection has failed!";
    echo "Attempted to connect to $ftp_server for user $ftp_user_name"; 
    exit; 
} 

else {
    echo "Connected to $ftp_server, for user $ftp_user_name";
}

// Upload the file
$upload = ftp_put($conn_id, $destination_file, $target_dir, FTP_BINARY); 

// Check upload status
if (!$upload) { 
    echo "FTP upload has failed!";
} 

else {
    echo "Uploaded $source_file to $ftp_server as $target_dir";
}

// Close the FTP stream 
ftp_close($conn_id);*/

?>
