<?php namespace TightenCo\Jigsaw;

class Jigsaw
{
    private $dataLoader;
    private $siteBuilder;

    public function __construct($dataLoader, $siteBuilder)
    {
        $this->dataLoader = $dataLoader;
        $this->siteBuilder = $siteBuilder;
    }

    public function build($source, $dest)
    {
        $siteData = $this->dataLoader->load($source);
        $this->siteBuilder->build($source, $dest, $siteData);
    }
}
