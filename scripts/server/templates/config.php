<?php

$string = file_get_contents(getcwd() . "/config.json");
$user_config = json_decode($string, true);

return [
    'production' => false,

    'site_domain' => $user_config->project->domain,
    'project_root' => $user_config->project->root
];
