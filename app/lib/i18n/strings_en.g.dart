///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAppEn app = _TranslationsAppEn._(_root);
	@override late final _TranslationsCommonEn common = _TranslationsCommonEn._(_root);
	@override late final _TranslationsServerSelectionEn serverSelection = _TranslationsServerSelectionEn._(_root);
	@override late final _TranslationsLoginEn login = _TranslationsLoginEn._(_root);
	@override late final _TranslationsHomeEn home = _TranslationsHomeEn._(_root);
	@override late final _TranslationsLibraryEn library = _TranslationsLibraryEn._(_root);
	@override late final _TranslationsSettingsEn settings = _TranslationsSettingsEn._(_root);
}

// Path: app
class _TranslationsAppEn extends TranslationsAppZhCn {
	_TranslationsAppEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Aether';
}

// Path: common
class _TranslationsCommonEn extends TranslationsCommonZhCn {
	_TranslationsCommonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get connect => 'Connect';
	@override String get save => 'Save';
	@override String get cancel => 'Cancel';
	@override String get delete => 'Delete';
	@override String get confirm => 'Confirm';
	@override String get loading => 'Loading...';
	@override String get error => 'Error';
	@override String get success => 'Success';
	@override String get retry => 'Retry';
}

// Path: serverSelection
class _TranslationsServerSelectionEn extends TranslationsServerSelectionZhCn {
	_TranslationsServerSelectionEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Select Server';
	@override String get subtitle => 'Choose a saved server or add a new one';
	@override String get addNew => 'Add New Server';
	@override String get lastLogin => 'Last login';
	@override String get deleteServer => 'Delete Server';
	@override String deleteConfirm({required Object serverName}) => 'Are you sure you want to delete @${serverName}?';
}

// Path: login
class _TranslationsLoginEn extends TranslationsLoginZhCn {
	_TranslationsLoginEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Connect to Server';
	@override String get serverUrl => 'Server URL';
	@override String get serverUrlHint => 'http://your-server:8096';
	@override String get username => 'Username';
	@override String get password => 'Password';
	@override String get signIn => 'Sign In';
	@override String get connectFirst => 'Please connect to server first';
	@override String get connectionFailed => 'Connection failed';
	@override String get loginFailed => 'Login failed';
	@override String get loginSuccess => 'Login successful';
	@override String get rememberMe => 'Remember this server';
}

// Path: home
class _TranslationsHomeEn extends TranslationsHomeZhCn {
	_TranslationsHomeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Home';
	@override String welcome({required Object name}) => 'Welcome back, @${name}';
	@override String get continueWatching => 'Continue Watching';
	@override String get recentlyAdded => 'Recently Added';
	@override String get favorites => 'Favorites';
	@override String get noItems => 'No items yet';
}

// Path: library
class _TranslationsLibraryEn extends TranslationsLibraryZhCn {
	_TranslationsLibraryEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Library';
	@override String get movies => 'Movies';
	@override String get tvShows => 'TV Shows';
	@override String get music => 'Music';
	@override String get all => 'All';
}

// Path: settings
class _TranslationsSettingsEn extends TranslationsSettingsZhCn {
	_TranslationsSettingsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get server => 'Server';
	@override String get serverInfo => 'Server Info';
	@override String get language => 'Language';
	@override String get theme => 'Theme';
	@override String get darkMode => 'Dark Mode';
	@override String get logout => 'Logout';
	@override String get logoutConfirm => 'Are you sure you want to logout?';
	@override String get chinese => '中文';
	@override String get english => 'English';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Aether',
			'common.connect' => 'Connect',
			'common.save' => 'Save',
			'common.cancel' => 'Cancel',
			'common.delete' => 'Delete',
			'common.confirm' => 'Confirm',
			'common.loading' => 'Loading...',
			'common.error' => 'Error',
			'common.success' => 'Success',
			'common.retry' => 'Retry',
			'serverSelection.title' => 'Select Server',
			'serverSelection.subtitle' => 'Choose a saved server or add a new one',
			'serverSelection.addNew' => 'Add New Server',
			'serverSelection.lastLogin' => 'Last login',
			'serverSelection.deleteServer' => 'Delete Server',
			'serverSelection.deleteConfirm' => ({required Object serverName}) => 'Are you sure you want to delete @${serverName}?',
			'login.title' => 'Connect to Server',
			'login.serverUrl' => 'Server URL',
			'login.serverUrlHint' => 'http://your-server:8096',
			'login.username' => 'Username',
			'login.password' => 'Password',
			'login.signIn' => 'Sign In',
			'login.connectFirst' => 'Please connect to server first',
			'login.connectionFailed' => 'Connection failed',
			'login.loginFailed' => 'Login failed',
			'login.loginSuccess' => 'Login successful',
			'login.rememberMe' => 'Remember this server',
			'home.title' => 'Home',
			'home.welcome' => ({required Object name}) => 'Welcome back, @${name}',
			'home.continueWatching' => 'Continue Watching',
			'home.recentlyAdded' => 'Recently Added',
			'home.favorites' => 'Favorites',
			'home.noItems' => 'No items yet',
			'library.title' => 'Library',
			'library.movies' => 'Movies',
			'library.tvShows' => 'TV Shows',
			'library.music' => 'Music',
			'library.all' => 'All',
			'settings.title' => 'Settings',
			'settings.server' => 'Server',
			'settings.serverInfo' => 'Server Info',
			'settings.language' => 'Language',
			'settings.theme' => 'Theme',
			'settings.darkMode' => 'Dark Mode',
			'settings.logout' => 'Logout',
			'settings.logoutConfirm' => 'Are you sure you want to logout?',
			'settings.chinese' => '中文',
			'settings.english' => 'English',
			_ => null,
		};
	}
}
