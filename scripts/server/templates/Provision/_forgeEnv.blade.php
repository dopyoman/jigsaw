
# Add The Environment Variables Scripts Into Forge Directory

cat > /home/$sudo_user/.$sudo_user/add-variable.php << EOF
<?php echo "
<?php

// Get the script input...
\$input = array_values(array_slice(\$_SERVER['argv'], 1));

// Get the path to the environment file...
\$path = getcwd().'/'.\$input[2];

// Write a stub file if one doesn't exist...
if ( ! file_exists(\$path)) {
	file_put_contents(\$path, '<?php return '.var_export([], true).';');
}

// Set the new environment variable...
\$env = require \$path;
\$env[\$input[0]] = \$input[1];

// Write the environment file to disk...
file_put_contents(\$path, '<?php return '.var_export(\$env, true).';');


EOF"
?>

cat > /home/forge/.forge/remove-variable.php << EOF
<?php echo "
<?php

// Get the script input...
\$input = array_values(array_slice(\$_SERVER['argv'], 1));

// Get the path to the environment file...
\$path = getcwd().'/'.\$input[1];

// Write a stub file if one doesn't exist...
if ( ! file_exists(\$path)) {
	file_put_contents(\$path, '<?php return '.var_export([], true).';');
}

// Remove the environment variable...
\$env = require \$path;
unset(\$env[\$input[0]]);

// Write the environment file to disk...
file_put_contents(\$path, '<?php return '.var_export(\$env, true).';');


EOF" ?>