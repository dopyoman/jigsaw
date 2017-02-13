<?php namespace TightenCo\Jigsaw\Console;

use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;
use TightenCo\Jigsaw\Jigsaw;
use TightenCo\Jigsaw\PathResolvers\PrettyOutputPathResolver;

class BuildCommand extends Command
{
    private $app;
    private $source;
    private $dest;

    public function __construct($app, $source, $dest)
    {
        $this->app = $app;
        $this->source = $source;
        $this->dest = $dest;
        parent::__construct();
    }

    protected function configure()
    {
        $this->setName('build')
            ->setDescription('Build your servers scripts and config files.');
    }

    protected function fire()
    {
        $this->app->make(Jigsaw::class)->build($this->source, $this->dest);

        $this->info('Site built successfully!');
    }
}
