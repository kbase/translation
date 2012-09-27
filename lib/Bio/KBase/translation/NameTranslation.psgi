use NameTranslationImpl;

use NameTranslationServer;



my @dispatch;

{
    my $obj = NameTranslationImpl->new;
    push(@dispatch, 'NameTranslation' => $obj);
}


my $server = NameTranslationServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler;
